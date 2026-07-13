const fs = require('fs');
const path = require('path');

const libDir = path.join(__dirname, '../lib');

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(function(file) {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) { 
            results = results.concat(walk(file));
        } else if (file.endsWith('.dart')) {
            results.push(file);
        }
    });
    return results;
}

const dartFiles = walk(libDir);

dartFiles.forEach(file => {
    let content = fs.readFileSync(file, 'utf8');
    
    // First, replace the AppTheme usages
    let newContent = content
        .replace(/AppTheme\.black/g, 'Theme.of(context).colorScheme.onSurface')
        .replace(/AppTheme\.white/g, 'Theme.of(context).colorScheme.surface')
        .replace(/AppTheme\.borderColor/g, '(Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB))')
        .replace(/AppTheme\.lightBackground/g, 'Theme.of(context).scaffoldBackgroundColor');

    // Remove `const` before widgets that might now contain dynamic theme elements.
    // e.g. `const TextStyle(` -> `TextStyle(`
    newContent = newContent
        .replace(/const\s+TextStyle\(/g, 'TextStyle(')
        .replace(/const\s+BoxDecoration\(/g, 'BoxDecoration(')
        .replace(/const\s+BorderSide\(/g, 'BorderSide(')
        .replace(/const\s+Padding\(/g, 'Padding(')
        .replace(/const\s+Divider\(/g, 'Divider(')
        .replace(/const\s+Card\(/g, 'Card(')
        .replace(/const\s+Text\(/g, 'Text(')
        .replace(/const\s+Container\(/g, 'Container(')
        .replace(/const\s+SizedBox\(/g, 'SizedBox(')
        .replace(/const\s+Icon\(/g, 'Icon(')
        .replace(/const\s+Color\(/g, 'Color(')
        .replace(/const\s+EdgeInsets/g, 'EdgeInsets')
        .replace(/const\s+BorderRadius/g, 'BorderRadius')
        .replace(/const\s+LinearGradient/g, 'LinearGradient')
        .replace(/const\s+Offset/g, 'Offset')
        .replace(/const\s+BoxShadow/g, 'BoxShadow');

    if (content !== newContent) {
        fs.writeFileSync(file, newContent, 'utf8');
        console.log(`Updated ${file}`);
    }
});
console.log('Done!');
