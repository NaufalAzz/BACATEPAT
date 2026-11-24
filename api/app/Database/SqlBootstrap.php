<?php

namespace App\Database;

use Illuminate\Support\Facades\DB;
use RuntimeException;

class SqlBootstrap
{
    public static function run(string $file): void
    {
        $sql = file_get_contents(database_path('sql/'.$file));
        // The standalone schema starts by selecting "bacatepat". Artisan must
        // use its configured database, including isolated test databases.
        $start = strpos($sql, 'SET NAMES utf8mb4');
        if ($start === false || DB::connection()->getDriverName() !== 'mysql') {
            throw new RuntimeException('Bootstrap BacaTepat memerlukan MySQL 8.');
        }
        $pdo = DB::connection()->getPdo();
        $emulated = $pdo->getAttribute(\PDO::ATTR_EMULATE_PREPARES);
        try {
            $pdo->setAttribute(\PDO::ATTR_EMULATE_PREPARES, true);
            $statement = $pdo->query(substr($sql, $start));
            while ($statement->nextRowset()) {
                // Consume every result so a failure in a later statement surfaces.
            }
        } catch (\Throwable $error) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            throw $error;
        } finally {
            $pdo->setAttribute(\PDO::ATTR_EMULATE_PREPARES, $emulated);
        }
    }
}
