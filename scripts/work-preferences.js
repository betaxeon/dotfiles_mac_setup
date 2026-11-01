// Run with macOS JavaScript for Automation, not Node. No UI scripting is used.
function run(args) {
    ObjC.import('Foundation');
    ObjC.import('CoreFoundation');
    var dryRun = args[0] === '--dry-run';
    var restore = args[0] === '--restore';
    if (!dryRun && !restore && args[0] !== '--apply') throw new Error('Expected --dry-run, --apply or --restore');
    var text = $.NSString.stringWithContentsOfFileEncodingError($(args[1]), $.NSUTF8StringEncoding, null);
    if (text.isNil()) throw new Error('Cannot read ' + args[1]);
    var data = JSON.parse(ObjC.unwrap(text));

    function domainID(domain) {
        return domain === 'NSGlobalDomain' ? $.kCFPreferencesAnyApplication : $(domain);
    }
    function hostID(domain) {
        return domain === 'com.apple.controlcenter' ? $.kCFPreferencesCurrentHost : $.kCFPreferencesAnyHost;
    }
    function read(domain, key) {
        var value = ObjC.castRefToObject($.CFPreferencesCopyValue(
            $(key), domainID(domain), $.kCFPreferencesCurrentUser, hostID(domain)));
        return value.isNil() ? null : ObjC.deepUnwrap(value);
    }
    function forced(domain, key) {
        return $.CFPreferencesAppValueIsForced($(key), domainID(domain));
    }
    // Preserve additional workplace input sources and language choices.
    function merge(wanted, current) {
        if (!Array.isArray(wanted) || !Array.isArray(current)) return wanted;
        var result = current.slice();
        wanted.forEach(function (item) {
            if (!result.some(function (old) { return equal(old, item); })) result.push(item);
        });
        return result;
    }
    function equal(a, b) {
        if (a === null || b === null) return a === b;
        return $(a).isEqual($(b));
    }

    var updates = [];
    if (restore) {
        updates = data;
    } else {
        if (data['com.apple.AppleMultitouchTrackpad']) {
            data['com.apple.driver.AppleBluetoothMultitouch.trackpad'] = data['com.apple.AppleMultitouchTrackpad'];
        }
        Object.keys(data).forEach(function (domain) {
            Object.keys(data[domain]).forEach(function (key) {
                updates.push({domain: domain, key: key, value: data[domain][key]});
            });
        });
    }

    var changes = [];
    updates.forEach(function (entry) {
        if (forced(entry.domain, entry.key)) {
            console.log('SKIP managed preference: ' + entry.domain + ' ' + entry.key);
            return;
        }
        var current = read(entry.domain, entry.key);
        // Avoid undoing subsequent user or workplace changes during restoration.
        if (restore && !equal(current, entry.applied)) {
            console.log('SKIP subsequently changed preference: ' + entry.domain + ' ' + entry.key);
            return;
        }
        var wanted = restore ? entry.value : merge(entry.value, current);
        if (equal(current, wanted)) return;
        changes.push({domain: entry.domain, key: entry.key, value: current, applied: wanted});
        console.log((dryRun ? 'WOULD SET ' : 'SET ') + entry.domain + ' ' + entry.key + ' = ' + JSON.stringify(wanted));
    });

    if (dryRun || changes.length === 0) return 'No preferences written.';
    if (!restore) {
        if (!args[2]) throw new Error('A backup path is required');
        if (!$(JSON.stringify(changes, null, 2)).writeToFileAtomicallyEncodingError(
            $(args[2]), true, $.NSUTF8StringEncoding, null)) throw new Error('Could not save preference backup');
    }
    changes.forEach(function (entry) {
        // Check again immediately before writing in case policy changed.
        if (forced(entry.domain, entry.key)) return;
        $.CFPreferencesSetValue($(entry.key), entry.applied === null ? null : $(entry.applied),
            domainID(entry.domain), $.kCFPreferencesCurrentUser, hostID(entry.domain));
        if (!$.CFPreferencesSynchronize(domainID(entry.domain), $.kCFPreferencesCurrentUser, hostID(entry.domain))) {
            throw new Error('Could not save preferences for ' + entry.domain);
        }
    });
    return 'Preferences saved. Log out and back in to refresh all settings.';
}
