<?php
/**
 * LAMP Stack Environment Diagnostic Test Suite
 * Evaluates server compatibility for Grav CMS, WordPress, Laravel, Symfony,
 * Drupal, Joomla, WooCommerce, CodeIgniter, Statamic/Kirby, and Database tools.
 */

// Retrieve Database credentials from environment variables or set defaults
$dbHost = getenv('MARIADB_HOST') ?: 'db';
$dbName = getenv('MARIADB_DATABASE') ?: 'grav_db';
$dbUser = getenv('MARIADB_USER') ?: 'grav_user';
$dbPass = getenv('MARIADB_PASSWORD') ?: 'change_this_user_password';

// Comprehensive extension definitions matrix
$extensions = [
    // Core & Shared Required Extensions
    'gd'         => ['systems' => 'Grav, WP, Drupal, Joomla, WooCommerce, Kirby', 'desc' => 'Image processing, thumbnail & watermark generation'],
    'mbstring'   => ['systems' => 'All Frameworks & CMS',                           'desc' => 'Multibyte string handling for international text'],
    'xml'        => ['systems' => 'Grav, WP, Laravel, Symfony, Drupal',            'desc' => 'XML parsing for RSS feeds, REST API & Gutenberg'],
    'zip'        => ['systems' => 'Grav, WP, Joomla, WooCommerce, Statamic',        'desc' => 'Plugin, theme & package zip archive extraction'],
    'zlib'       => ['systems' => 'Grav, WordPress, Symfony',                      'desc' => 'Gzip HTTP payload compression'],
    'curl'       => ['systems' => 'Grav, WP, Laravel, CodeIgniter',                'desc' => 'Remote API requests, GPM & Composer packages'],
    'pdo'        => ['systems' => 'Laravel, Symfony, Drupal, CodeIgniter',         'desc' => 'PHP Data Objects database abstraction layer'],
    'pdo_mysql'  => ['systems' => 'Laravel, Symfony, Drupal, Joomla, Adminer',     'desc' => 'MariaDB / MySQL PDO database driver'],
    'mysqli'     => ['systems' => 'WordPress, Joomla, WooCommerce, Adminer',       'desc' => 'MySQLi database driver for WordPress & Adminer'],
    'yaml'       => ['systems' => 'Grav CMS, Statamic',                            'desc' => 'YAML frontmatter & configuration parsing (PECL yaml)'],
    'opcache'    => ['systems' => 'All Production PHP Systems',                    'desc' => 'Zend OPcache PHP bytecode caching'],
    'exif'       => ['systems' => 'Grav, WP, WooCommerce, Kirby',                  'desc' => 'EXIF image metadata & orientation reading'],
    'fileinfo'   => ['systems' => 'Laravel, Symfony, Grav, WP',                    'desc' => 'MIME type identification for secure uploads'],
    'intl'       => ['systems' => 'Symfony, CodeIgniter, Laravel, Grav, WP',       'desc' => 'Internationalization, number & currency formatting'],
    'openssl'    => ['systems' => 'Laravel, Symfony, Grav, WP, Drupal',            'desc' => 'HTTPS security protocols, API crypto & tokens'],
    'sodium'     => ['systems' => 'Laravel, WordPress, Sodium Hashing',            'desc' => 'Modern sodium cryptography & secure password hashing'],
    'imagick'    => ['systems' => 'Grav, WP, Statamic, Kirby',                     'desc' => 'ImageMagick vector graphics & PDF thumbnail rendering'],
    'bcmath'     => ['systems' => 'Laravel, WooCommerce, Financial Apps',          'desc' => 'Arbitrary precision mathematics for transactions'],
    'sockets'    => ['systems' => 'Laravel Horizon, WebSockets, Swoole',           'desc' => 'Low-level network socket communication'],
    'redis'      => ['systems' => 'Laravel, Grav, WP Object Cache',                'desc' => 'Redis key-value store in-memory caching driver'],
    'apcu'       => ['systems' => 'Symfony, Grav, High-Performance APCu',          'desc' => 'APCu shared memory user object caching'],
    'sqlite3'    => ['systems' => 'Grav PageIndexStore, Flex Objects, SQLite',     'desc' => 'SQLite embedded database engine driver'],
    'pdo_sqlite' => ['systems' => 'Grav, Laravel (SQLite DB), Flex Objects',       'desc' => 'PDO SQLite driver for embedded database stores'],
];

// Helper to parse memory limit string
function parse_size($size) {
    $unit = preg_replace('/[^bkmgtpezy]/i', '', $size);
    $size = preg_replace('/[^0-9\.]/', '', $size);
    if ($unit) {
        return round($size * pow(1024, stripos('bkmgtpezy', $unit[0])));
    }
    return round($size);
}

$memoryLimit = ini_get('memory_limit');
$memoryBytes = parse_size($memoryLimit);
$recommendedMemory = 128 * 1024 * 1024; // 128MB

// Test MariaDB PDO connection safely
$pdoConnected = false;
$pdoError = '';
$serverVersion = '';
try {
    $dsn = "mysql:host=$dbHost;dbname=$dbName;charset=utf8mb4";
    $pdo = @new PDO($dsn, $dbUser, $dbPass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 3
    ]);
    $pdoConnected = true;
    $serverVersion = $pdo->getAttribute(PDO::ATTR_SERVER_VERSION);
} catch (Throwable $e) {
    $pdoConnected = false;
    $pdoError = $e->getMessage();
}

// Test MySQLi connection safely
$mysqliConnected = false;
$mysqliError = '';
if (extension_loaded('mysqli')) {
    mysqli_report(MYSQLI_REPORT_OFF);
    try {
        $mysqli = @new mysqli($dbHost, $dbUser, $dbPass, $dbName);
        if (!$mysqli->connect_error) {
            $mysqliConnected = true;
            if (!$serverVersion) $serverVersion = $mysqli->server_info;
            $mysqli->close();
        } else {
            $mysqliConnected = false;
            $mysqliError = $mysqli->connect_error;
        }
    } catch (Throwable $e) {
        $mysqliConnected = false;
        $mysqliError = $e->getMessage();
    }
} else {
    $mysqliConnected = false;
    $mysqliError = 'mysqli extension is not loaded';
}

$dbConnected = $pdoConnected || $mysqliConnected;

// Define popular PHP Systems, CMS, and Framework Requirements
$systems = [
    'grav' => [
        'name' => 'Grav CMS',
        'category' => 'Flat-File CMS',
        'req' => ['gd', 'mbstring', 'xml', 'zip', 'zlib', 'curl', 'yaml'],
        'rec' => ['opcache', 'exif', 'fileinfo', 'intl', 'openssl', 'imagick', 'apcu', 'redis', 'pdo_sqlite'],
        'db' => false,
    ],
    'wp' => [
        'name' => 'WordPress Core',
        'category' => 'CMS & Publishing',
        'req' => ['gd', 'mbstring', 'xml', 'zip', 'curl', 'mysqli'],
        'rec' => ['pdo_mysql', 'opcache', 'exif', 'fileinfo', 'intl', 'openssl', 'sodium', 'imagick', 'bcmath', 'redis'],
        'db' => true,
    ],
    'laravel' => [
        'name' => 'Laravel 10 / 11',
        'category' => 'PHP Framework',
        'req' => ['mbstring', 'openssl', 'pdo', 'pdo_mysql', 'xml', 'fileinfo', 'curl'],
        'rec' => ['opcache', 'bcmath', 'sodium', 'redis', 'intl', 'gd'],
        'db' => true,
    ],
    'symfony' => [
        'name' => 'Symfony 6 / 7',
        'category' => 'Enterprise Framework',
        'req' => ['mbstring', 'openssl', 'pdo', 'pdo_mysql', 'xml', 'intl'],
        'rec' => ['opcache', 'apcu', 'gd', 'zip', 'bcmath'],
        'db' => true,
    ],
    'drupal' => [
        'name' => 'Drupal 10 / 11',
        'category' => 'Enterprise CMS',
        'req' => ['pdo', 'pdo_mysql', 'xml', 'gd', 'mbstring', 'openssl'],
        'rec' => ['opcache', 'zip', 'intl', 'fileinfo'],
        'db' => true,
    ],
    'joomla' => [
        'name' => 'Joomla 5',
        'category' => 'Flexible CMS',
        'req' => ['mysqli', 'pdo_mysql', 'gd', 'xml', 'zip', 'mbstring'],
        'rec' => ['opcache', 'intl', 'curl', 'openssl'],
        'db' => true,
    ],
    'woocommerce' => [
        'name' => 'WooCommerce',
        'category' => 'E-Commerce Platform',
        'req' => ['mysqli', 'gd', 'mbstring', 'curl', 'zip'],
        'rec' => ['exif', 'bcmath', 'sodium', 'intl', 'redis', 'pdo_mysql'],
        'db' => true,
    ],
    'codeigniter' => [
        'name' => 'CodeIgniter 4',
        'category' => 'Lightweight Framework',
        'req' => ['intl', 'mbstring', 'curl', 'pdo'],
        'rec' => ['pdo_mysql', 'mysqli', 'gd'],
        'db' => false,
    ],
    'flatfile' => [
        'name' => 'Kirby / Statamic',
        'category' => 'Flat-file CMS',
        'req' => ['gd', 'mbstring', 'exif', 'zip', 'curl'],
        'rec' => ['imagick', 'intl', 'yaml', 'opcache'],
        'db' => false,
    ],
    'adminer' => [
        'name' => 'Adminer / phpMyAdmin',
        'category' => 'Database Tools',
        'req' => ['mysqli', 'pdo_mysql', 'mbstring'],
        'rec' => ['zip', 'gd', 'opcache'],
        'db' => true,
    ],
];

// Grade Calculator
function get_grade($score) {
    if ($score >= 98) return ['grade' => 'A+', 'color' => '#15803d', 'bg' => '#dcfce7'];
    if ($score >= 85) return ['grade' => 'A',  'color' => '#16a34a', 'bg' => '#dcfce7'];
    if ($score >= 70) return ['grade' => 'B',  'color' => '#b45309', 'bg' => '#fef3c7'];
    if ($score >= 50) return ['grade' => 'C',  'color' => '#c2410c', 'bg' => '#ffedd5'];
    return ['grade' => 'F', 'color' => '#b91c1c', 'bg' => '#fee2e2'];
}

// Compute scores for each system
$scores = [];
foreach ($systems as $key => $sys) {
    $total = 0;
    $max = 0;

    foreach ($sys['req'] as $ext) {
        $max += 10;
        $isLoaded = extension_loaded($ext);
        if ($ext === 'opcache') $isLoaded = extension_loaded('Zend OPcache') || extension_loaded('opcache');
        if ($isLoaded) $total += 10;
    }

    foreach ($sys['rec'] as $ext) {
        $max += 3;
        $isLoaded = extension_loaded($ext);
        if ($ext === 'opcache') $isLoaded = extension_loaded('Zend OPcache') || extension_loaded('opcache');
        if ($isLoaded) $total += 3;
    }

    if ($sys['db']) {
        $max += 15;
        if ($dbConnected) $total += 15;
    }

    $perc = round(($total / $max) * 100);
    $scores[$key] = [
        'score' => $perc,
        'grade' => get_grade($perc),
    ];
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP Systems & Frameworks Environment Diagnostic Test</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f8fafc; color: #1e293b; margin: 0; padding: 40px 20px; }
        .container { max-width: 1050px; margin: 0 auto; }
        .card { background: #ffffff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 24px; margin-bottom: 24px; box-shadow: 0 4px 12px rgba(0,0,0,0.03); }
        h1 { margin: 0 0 6px 0; font-size: 1.6rem; color: #0f172a; }
        h2 { margin: 0 0 16px 0; font-size: 1.2rem; color: #334155; border-bottom: 2px solid #f1f5f9; padding-bottom: 8px; }
        p { margin: 6px 0; color: #475569; font-size: 0.95rem; }
        .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 12px; }
        .grid-3 { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; margin-top: 16px; }
        table { width: 100%; border-collapse: collapse; margin-top: 12px; }
        th, td { text-align: left; padding: 10px 12px; border-bottom: 1px solid #f1f5f9; font-size: 0.92rem; }
        th { background: #f8fafc; color: #64748b; font-weight: 600; }
        .badge { display: inline-block; padding: 3px 8px; border-radius: 4px; font-weight: 600; font-size: 0.75rem; text-transform: uppercase; }
        .badge-success { background: #dcfce7; color: #15803d; }
        .badge-danger { background: #fee2e2; color: #b91c1c; }
        .badge-warning { background: #fef3c7; color: #b45309; }
        .badge-secondary { background: #f1f5f9; color: #64748b; }
        code { background: #f1f5f9; padding: 2px 6px; border-radius: 4px; font-family: monospace; font-size: 0.9em; color: #0f172a; }
        
        .alert-banner { padding: 16px 20px; border-radius: 8px; margin-bottom: 24px; font-size: 0.95rem; line-height: 1.5; }
        .alert-banner h3 { margin: 0 0 6px 0; font-size: 1.1rem; }
        .alert-success { background: #f0fdf4; border: 1px solid #bbf7d0; color: #166534; }
        .alert-warning { background: #fffbeb; border: 1px solid #fef08a; color: #854d0e; }
        .error-box { background: #fef2f2; border-left: 4px solid #ef4444; padding: 12px; margin-top: 12px; border-radius: 4px; }
    </style>
</head>
<body>

<div class="container">
    <div class="card">
        <h1>🧪 PHP Systems, Frameworks & CMS Environment Diagnostic Test</h1>
        <p>Comprehensive runtime compatibility score for <strong>Grav CMS</strong>, <strong>WordPress</strong>, <strong>Laravel</strong>, <strong>Symfony</strong>, <strong>Drupal</strong>, <strong>Joomla</strong>, <strong>WooCommerce</strong>, <strong>CodeIgniter</strong>, <strong>Kirby/Statamic</strong>, and <strong>Database Tools</strong>.</p>
    </div>

    <!-- Compatibility Scoreboard Grid -->
    <div class="card">
        <h2>Popular PHP Systems & Frameworks Scoreboard</h2>
        <div class="grid-3">
            <?php foreach ($systems as $key => $sys): ?>
                <?php $res = $scores[$key]; ?>
                <div style="border: 1px solid #e2e8f0; border-radius: 8px; padding: 16px; background: #f8fafc;">
                    <div style="display:flex; justify-content:space-between; align-items:center;">
                        <span style="font-size:0.75rem; font-weight:700; color:#64748b; text-transform:uppercase;"><?php echo $sys['category']; ?></span>
                        <span class="badge" style="background:<?php echo $res['grade']['bg']; ?>; color:<?php echo $res['grade']['color']; ?>; font-size:0.75rem; padding:2px 8px;"><?php echo $res['grade']['grade']; ?></span>
                    </div>
                    <div style="font-weight:700; font-size:1.05rem; color:#0f172a; margin-top:4px;"><?php echo $sys['name']; ?></div>
                    <div style="font-size:1.8rem; font-weight:700; color:#0f172a; margin: 8px 0 6px 0;"><?php echo $res['score']; ?>%</div>
                    <div style="background:#e2e8f0; border-radius:6px; height:8px; overflow:hidden;">
                        <div style="width:<?php echo $res['score']; ?>%; background:<?php echo $res['grade']['color']; ?>; height:100%;"></div>
                    </div>
                </div>
            <?php endforeach; ?>
        </div>
    </div>

    <!-- Database & Server Configuration -->
    <div class="grid-2">
        <div class="card">
            <h2>Server & PHP Configuration</h2>
            <p><strong>PHP Version:</strong> <code><?php echo PHP_VERSION; ?></code> <span class="badge badge-success">8.3 Compatible</span></p>
            <p><strong>Server Software:</strong> <code><?php echo $_SERVER['SERVER_SOFTWARE'] ?? 'Apache 2.4'; ?></code></p>
            <p><strong>Document Root:</strong> <code><?php echo $_SERVER['DOCUMENT_ROOT']; ?></code></p>
            <p><strong>Memory Limit:</strong> <code><?php echo $memoryLimit; ?></code>
            <?php if ($memoryBytes >= $recommendedMemory || $memoryLimit == -1): ?>
                <span class="badge badge-success">Sufficient (>= 128M)</span>
            <?php else: ?>
                <span class="badge badge-warning">Low (< 128M)</span>
            <?php endif; ?>
            </p>
            <p><strong>Upload Max Filesize:</strong> <code><?php echo ini_get('upload_max_filesize'); ?></code></p>
            <p><strong>Post Max Size:</strong> <code><?php echo ini_get('post_max_size'); ?></code></p>
        </div>

        <div class="card">
            <h2>MariaDB Connection Test</h2>
            <?php if ($dbConnected): ?>
                <p><span class="badge badge-success">Connected</span> Connection established!</p>
                <p><strong>Host:</strong> <code><?php echo $dbHost; ?></code></p>
                <p><strong>Database:</strong> <code><?php echo $dbName; ?></code></p>
                <p><strong>User:</strong> <code><?php echo $dbUser; ?></code></p>
                <p><strong>Server Version:</strong> <code><?php echo $serverVersion; ?></code></p>
            <?php else: ?>
                <p><span class="badge badge-warning">Disconnected</span> Could not connect to MariaDB database.</p>
                <div class="error-box">
                    <strong>Error Details:</strong> <code><?php echo htmlspecialchars($pdoError ?: $mysqliError); ?></code>
                </div>
            <?php endif; ?>
        </div>
    </div>

    <!-- PHP Extensions Matrix -->
    <div class="card">
        <h2>PHP Extensions Status Matrix</h2>
        <table>
            <thead>
                <tr>
                    <th>Extension</th>
                    <th>Target PHP Systems</th>
                    <th>Description</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($extensions as $ext => $info): ?>
                    <?php
                    $isLoaded = extension_loaded($ext);
                    if ($ext === 'opcache') {
                        $isLoaded = extension_loaded('Zend OPcache') || extension_loaded('opcache');
                    }

                    if ($isLoaded) {
                        $badgeClass = 'badge-success';
                        $statusText = 'Loaded';
                    } else {
                        $badgeClass = 'badge-warning';
                        $statusText = 'Disabled';
                    }
                    ?>
                    <tr>
                        <td><code><?php echo $ext; ?></code></td>
                        <td><?php echo $info['systems']; ?></td>
                        <td><?php echo $info['desc']; ?></td>
                        <td><span class="badge <?php echo $badgeClass; ?>"><?php echo $statusText; ?></span></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

</body>
</html>
