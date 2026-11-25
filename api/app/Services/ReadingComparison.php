<?php

namespace App\Services;

class ReadingComparison
{
    /** Align Indonesian words to distinguish a missed word from a substitution. */
    public function compare(string $target, string $transcript): array
    {
        $tokenize = static fn (string $text) => preg_split('/[^\p{L}\p{N}]+/u', mb_strtolower($text), -1, PREG_SPLIT_NO_EMPTY);
        $expected = $tokenize($target);
        $heard = $tokenize($transcript);
        $n = count($expected);
        $m = count($heard);
        $distance = [range(0, $m)];
        for ($i = 1; $i <= $n; $i++) {
            $distance[$i] = [$i];
            for ($j = 1; $j <= $m; $j++) {
                $distance[$i][$j] = min($distance[$i - 1][$j] + 1, $distance[$i][$j - 1] + 1,
                    $distance[$i - 1][$j - 1] + (int) ($expected[$i - 1] !== $heard[$j - 1]));
            }
        }
        $missed = $changed = $repeated = [];
        $i = $n;
        $j = $m;
        while ($i || $j) {
            if ($i && $j && $distance[$i][$j] === $distance[$i - 1][$j - 1] + (int) ($expected[$i - 1] !== $heard[$j - 1])) {
                if ($expected[$i - 1] !== $heard[$j - 1]) {
                    $changed[] = ['target' => $expected[$i - 1], 'terdengar' => $heard[$j - 1]];
                }
                $i--;
                $j--;
            } elseif ($i && $distance[$i][$j] === $distance[$i - 1][$j] + 1) {
                $missed[] = $expected[--$i];
            } else {
                $j--;
                if (($heard[$j - 1] ?? null) === $heard[$j] || ($heard[$j + 1] ?? null) === $heard[$j]) {
                    $repeated[] = $heard[$j];
                }
            }
        }

        return ['missed_words' => json_encode(array_reverse($missed)), 'changed_words' => json_encode(array_reverse($changed)),
            'repeated_words' => json_encode(array_reverse($repeated)), 'similarity_score' => round(100 * (1 - $distance[$n][$m] / max(1, $n, $m)), 2)];
    }
}
