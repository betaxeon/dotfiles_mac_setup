import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { cpSync, existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import test from 'node:test';
import vm from 'node:vm';
import { isDeepStrictEqual } from 'node:util';

const root = path.resolve(import.meta.dirname, '..');

function fixture(t) {
    const temp = mkdtempSync(path.join(tmpdir(), 'dotfiles-work-'));
    t.after(() => rmSync(temp, { recursive: true, force: true }));
    const repo = path.join(temp, 'checkout with spaces');
    const home = path.join(temp, 'home');
    const bin = path.join(temp, 'bin');
    for (const dir of [repo, home, bin]) mkdirSync(dir);
    for (const name of ['bootstrap.sh', 'rebuild.sh', 'scripts', 'app-configs', 'home', '.zprofile', '.zshrc', '.tmux.conf', '.wezterm.lua', 'macos-preferences.json']) {
        cpSync(path.join(root, name), path.join(repo, name), { recursive: true });
    }
    writeFileSync(path.join(repo, 'work-packages.txt'), 'gh gh\ntmux tmux\nzsh-autosuggestions -\n');
    const log = path.join(temp, 'commands');
    const command = (name, body) => writeFileSync(path.join(bin, name), '#!/bin/bash\n' + body, { mode: 0o755 });
    command('uname', 'echo Darwin\n');
    command('gh', 'exit 0\n');
    command('brew', `printf 'brew %s | no-sudo=%s\n' "$*" "$HOMEBREW_NO_SUDO" >> "$TEST_LOG"
if [[ "$1" == list ]]; then [[ "$*" == 'list --versions tmux' ]]; else exit 0; fi
`);
    command('osascript', 'printf "osascript %s\\n" "$*" >> "$TEST_LOG"\n');
    for (const name of ['sudo', 'nix', 'curl', 'chown', 'launchctl']) {
        command(name, `echo 'FORBIDDEN ${name}' >> "$TEST_LOG"; exit 99\n`);
    }
    const env = { ...process.env, HOME: home, PATH: `${bin}:/usr/bin:/bin:/usr/sbin:/sbin`, TEST_LOG: log };
    delete env.ZDOTDIR;
    delete env.XDG_CONFIG_HOME;
    const run = (script, ...args) => spawnSync('/bin/bash', [path.join(repo, script), ...args], { env, encoding: 'utf8' });
    const commands = () => existsSync(log) ? readFileSync(log, 'utf8') : '';
    return { repo, home, env, run, commands };
}

test('work bootstrap and saved-mode rebuild preserve workplace files and never elevate', t => {
    const f = fixture(t);
    writeFileSync(path.join(f.home, '.zshrc'), 'export COMPANY_SETTING=retained\n');
    writeFileSync(path.join(f.home, '.gitconfig'), '[user]\n email = employee@example.com\n');
    writeFileSync(path.join(f.home, '.tmux.conf'), '# company tmux settings\n');
    mkdirSync(path.join(f.home, '.codex'));
    writeFileSync(path.join(f.home, '.codex/AGENTS.md'), 'Company instructions\n');
    let result = f.run('bootstrap.sh', '--mode', 'work');
    assert.equal(result.status, 0, result.stderr + result.stdout);
    assert.equal(readFileSync(path.join(f.repo, '.setup-mode'), 'utf8'), 'work\n');
    const shell = readFileSync(path.join(f.home, '.zshrc'), 'utf8');
    assert.match(shell, /^export COMPANY_SETTING=retained\n/);
    assert.match(shell, /checkout\\ with\\ spaces/);
    assert.equal(readFileSync(path.join(f.home, '.gitconfig'), 'utf8'), '[user]\n email = employee@example.com\n');
    assert.equal(readFileSync(path.join(f.home, '.tmux.conf'), 'utf8'), '# company tmux settings\n');
    assert.equal(readFileSync(path.join(f.home, '.codex/AGENTS.md'), 'utf8'), 'Company instructions\n');
    assert.ok(lstatSync(path.join(f.home, '.wezterm.lua')).isSymbolicLink());
    assert.match(f.commands(), /brew install --formula zsh-autosuggestions \| no-sudo=1/);
    assert.doesNotMatch(f.commands(), /install --formula (gh|tmux)/);
    assert.match(f.commands(), /osascript .*--apply/);
    const shellRun = spawnSync('/bin/zsh', ['-d', '-i', '-c', 'print -- "$COMPANY_SETTING"; alias m'], {
        env: { ...f.env, ZDOTDIR: f.home }, encoding: 'utf8', timeout: 10000,
    });
    assert.equal(shellRun.status, 0, shellRun.stderr);
    assert.match(shellRun.stdout, /retained/);
    assert.match(shellRun.stdout, /git switch main/);
    result = f.run('rebuild.sh', '--skip-packages');
    assert.equal(result.status, 0, result.stderr + result.stdout);
    assert.equal(readFileSync(path.join(f.home, '.zshrc'), 'utf8'), shell);
    assert.doesNotMatch(f.commands(), /FORBIDDEN|brew (upgrade|update|cleanup|uninstall)/);
});

test('dry run does not save a mode, change files, install packages, or apply preferences', t => {
    const f = fixture(t);
    writeFileSync(path.join(f.home, '.zshrc'), '# company shell\n');
    const result = f.run('bootstrap.sh', '--mode', 'work', '--dry-run');
    assert.equal(result.status, 0, result.stderr + result.stdout);
    assert.equal(readFileSync(path.join(f.home, '.zshrc'), 'utf8'), '# company shell\n');
    assert.ok(!existsSync(path.join(f.repo, '.setup-mode')));
    assert.ok(!existsSync(path.join(f.home, '.local')));
    assert.ok(!existsSync(path.join(f.home, '.wezterm.lua')));
    assert.doesNotMatch(f.commands(), /brew install|--apply|FORBIDDEN/);
    assert.match(f.commands(), /--dry-run/);
});

test('missing/invalid modes and personal work-only flags fail before external commands', t => {
    const f = fixture(t);
    for (const args of [[], ['--mode'], ['--mode', 'system'], ['--mode', 'dotfiles'], ['--mode', 'personal', '--dry-run']]) {
        const result = f.run('bootstrap.sh', ...args);
        assert.notEqual(result.status, 0);
        assert.ok(!existsSync(path.join(f.repo, '.setup-mode')));
        assert.equal(f.commands(), '');
    }
});

test('skip flags permit file setup without running package or preference tools', t => {
    const f = fixture(t);
    const result = f.run('bootstrap.sh', '--mode', 'work', '--skip-packages', '--skip-preferences');
    assert.equal(result.status, 0, result.stderr + result.stdout);
    assert.equal(f.commands(), '');
    assert.ok(lstatSync(path.join(f.home, '.wezterm.lua')).isSymbolicLink());
});

test('native macOS preference preview handles changed typed values without writing', { skip: process.platform !== 'darwin' }, t => {
    const f = fixture(t);
    const input = path.join(f.repo, 'preview.json');
    writeFileSync(input, JSON.stringify({ 'org.dotfiles.readonly-preview': {
        Bool: true, Integer: 15, Float: 0.875, Array: ['en-AU'], Object: { nested: 'value' },
    } }));
    const result = spawnSync('/usr/bin/osascript', ['-l', 'JavaScript',
        path.join(root, 'scripts/work-preferences.js'), '--dry-run', input], { encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr + result.stdout);
    assert.match(result.stderr, /WOULD SET .* Bool = true/);
    assert.match(result.stderr, /WOULD SET .* Float = 0.875/);
    assert.match(result.stdout, /No preferences written/);
});

// Exercise the actual JXA program with an in-memory macOS preferences API.
// Tests must never write the developer's real user preferences.
function preferences(input, initial = {}, forced = []) {
    const state = new Map(Object.entries(initial));
    const files = new Map([['input', JSON.stringify(input)]]);
    const writes = [];
    const unwrap = obj => obj?.value;
    function $(value) {
        return {
            value,
            isNil: () => value === null || value === undefined,
            isEqual: other => isDeepStrictEqual(value, unwrap(other)),
            writeToFileAtomicallyEncodingError: file => { files.set(unwrap(file), value); return true; },
        };
    }
    $.NSString = { stringWithContentsOfFileEncodingError: file => $(files.get(unwrap(file))) };
    $.kCFPreferencesAnyApplication = $('global');
    $.kCFPreferencesCurrentUser = $('user');
    $.kCFPreferencesCurrentHost = $('current-host');
    $.kCFPreferencesAnyHost = $('any-host');
    const keyFor = (key, domain) => `${unwrap(domain)}:${unwrap(key)}`;
    $.CFPreferencesCopyValue = (key, domain) => $(state.get(keyFor(key, domain)) ?? null);
    $.CFPreferencesAppValueIsForced = (key, domain) => forced.includes(keyFor(key, domain));
    $.CFPreferencesSetValue = (key, value, domain, user, host) => {
        const k = keyFor(key, domain);
        state.set(k, value === null ? null : unwrap(value));
        writes.push({ key: k, user: unwrap(user), host: unwrap(host) });
    };
    $.CFPreferencesSynchronize = () => true;
    const context = vm.createContext({ $, console: { log() {} }, ObjC: {
        import() {}, unwrap, deepUnwrap: unwrap, castRefToObject: value => value,
    } });
    vm.runInContext(readFileSync(path.join(root, 'scripts/work-preferences.js'), 'utf8'), context);
    return { state, writes, files, run: (mode, file = 'input') => context.run([mode, file, 'backup']) };
}

test('preferences skip managed keys, merge input sources, and back up only changed keys', () => {
    const input = JSON.parse(readFileSync(path.join(root, 'macos-preferences.json'), 'utf8'));
    const p = preferences(input, {
        'com.apple.dock:autohide': false,
        'com.apple.HIToolbox:AppleEnabledInputSources': [{ InputSourceKind: 'Keyboard Layout', 'KeyboardLayout Name': 'Company' }],
        'NSGlobalDomain:unrelated': 'keep',
    }, ['com.apple.dock:autohide']);
    p.run('--apply');
    assert.equal(p.state.get('com.apple.dock:autohide'), false);
    assert.equal(p.state.get('NSGlobalDomain:unrelated'), 'keep');
    assert.equal(p.state.get('com.apple.HIToolbox:AppleEnabledInputSources')[0]['KeyboardLayout Name'], 'Company');
    assert.ok(p.writes.every(write => write.user === 'user'));
    assert.equal(p.writes.find(write => write.key === 'com.apple.controlcenter:Bluetooth').host, 'current-host');
    const backup = JSON.parse(p.files.get('backup'));
    assert.ok(backup.length > 0);
    assert.ok(!backup.some(entry => entry.key === 'autohide'));
    const before = p.writes.length;
    p.run('--apply');
    assert.equal(p.writes.length, before, 'reapplying should not create duplicate inputs or writes');
});

test('preference preview writes nothing; restore preserves subsequent changes', () => {
    const p = preferences({ 'com.apple.dock': { autohide: true }, 'com.apple.finder': { FXPreferredViewStyle: 'clmv' } });
    p.run('--dry-run');
    assert.equal(p.writes.length, 0);
    assert.ok(!p.files.has('backup'));
    p.run('--apply');
    p.state.set('com.apple.finder:FXPreferredViewStyle', 'Nlsv');
    p.run('--restore', 'backup');
    assert.equal(p.state.get('com.apple.dock:autohide'), null);
    assert.equal(p.state.get('com.apple.finder:FXPreferredViewStyle'), 'Nlsv');
});
