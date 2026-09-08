# Generates the game's SFX as 16-bit mono 44100Hz WAVs into .\audio.
# Re-run to regenerate: powershell -File gen_audio.ps1
# ponytail: one-off tooling to keep sounds reproducible; the WAVs are the shipped asset.

$ErrorActionPreference = 'Stop'
$OUT = Join-Path $PSScriptRoot 'audio'
New-Item -ItemType Directory -Force -Path $OUT | Out-Null
$RATE = 44100

function Write-WavSound($outputPath, [double[]]$samples) {
    $count = $samples.Length
    $dataLen = $count * 2
    $w = New-Object System.IO.BinaryWriter([System.IO.FileStream]::new($outputPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write))
    $w.Write([byte[]][System.Text.Encoding]::ASCII.GetBytes('RIFF')); $w.Write([int32](36 + $dataLen))
    $w.Write([byte[]][System.Text.Encoding]::ASCII.GetBytes('WAVE'))
    $w.Write([byte[]][System.Text.Encoding]::ASCII.GetBytes('fmt ')); $w.Write([int32]16)
    $w.Write([int16]1); $w.Write([int16]1); $w.Write([int32]$RATE); $w.Write([int32]($RATE * 2)); $w.Write([int16]2); $w.Write([int16]16)
    $w.Write([byte[]][System.Text.Encoding]::ASCII.GetBytes('data')); $w.Write([int32]$dataLen)
    for ($i = 0; $i -lt $count; $i++) {
        $v = [int16]([math]::Max(-1.0, [math]::Min(1.0, $samples[$i])) * 32767.0)
        $w.Write($v)
    }
    $w.Close()
}

function Save-Wav($outputPath, $samples) {
    $peak = 0.0
    foreach ($s in $samples) { $a = [math]::Abs($s); if ($a -gt $peak) { $peak = $a } }
    if ($peak -gt 1.0) { for ($i = 0; $i -lt $samples.Length; $i++) { $samples[$i] *= 0.95 / $peak } }
    Write-WavSound $outputPath $samples
}

function New-Silence($seconds) {
    $n = [int]($RATE * $seconds)
    $s = New-Object 'double[]' $n
    return ,$s
}

function Get-BrownNoise($seconds, $step) {
    $n = [int]($RATE * $seconds)
    $s = New-Object 'double[]' $n
    $rng = [System.Random]::new(1337)
    $v = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $v += ($rng.NextDouble() - 0.5) * $step
        $v = [math]::Max(-1.0, [math]::Min(1.0, $v))
        $s[$i] = $v
    }
    return ,$s
}

# --- engine: 55->pitch shifted at runtime, loop = base freq 60Hz (integer cycles / 1s) ---
$sec = 1.0; $n = [int]($RATE * $sec); $s = New-Object 'double[]' $n
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $RATE
    $saw1 = 2.0 * ($t * 60 - [math]::Floor($t * 60 + 0.5))
    $saw2 = 2.0 * ($t * 120 - [math]::Floor($t * 120 + 0.5))
    $s[$i] = 0.55 * $saw1 + 0.20 * $saw2 + 0.12 * [math]::Sin(2 * [math]::PI * 30 * $t) + 0.05 * [math]::Sin(2 * [math]::PI * 240 * $t)
}
Save-Wav (Join-Path $OUT 'engine.wav') $s

# --- drift: brown noise + an FM'd screech tone, crossfaded so it loops ---
$sec = 2.0; $n = [int]($RATE * $sec)
$b = Get-BrownNoise $sec 0.11
$lp = New-Object 'double[]' $n
for ($i = 1; $i -lt $n; $i++) { $lp[$i] = $lp[$i - 1] + ($b[$i] - $b[$i - 1]) * 0.22; $lp[$i] = [math]::Max(-1.0,[math]::Min(1.0,$lp[$i])) }
$s = New-Object 'double[]' $n
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $RATE
    $fade = [math]::Min($t * 20.0, [math]::Min((($sec - $t) * 20.0), 1.0))
    $vib = 0.6 + 0.4 * [math]::Sin(2 * [math]::PI * 4 * $t)
    $s[$i] = (0.5 * $lp[$i] + 0.30 * [math]::Sin(2 * [math]::PI * 880 * $t) * $vib + 0.18 * [math]::Sin(2 * [math]::PI * 1170 * $t)) * $fade
}
Save-Wav (Join-Path $OUT 'drift.wav') $s

# --- crash: decaying thud + noise burst ---
$sec = 0.35; $n = [int]($RATE * $sec)
$b = Get-BrownNoise $sec 0.25
$s = New-Object 'double[]' $n
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $RATE
    $s[$i] = 1.0 * $b[$i] * [math]::Exp(-$t / 0.09) + 0.5 * [math]::Sin(2 * [math]::PI * 120 * $t) * [math]::Exp(-$t / 0.07)
}
Save-Wav (Join-Path $OUT 'crash.wav') $s

# --- scrape: metallic rasp for road-edge contact ---
$sec = 0.25; $n = [int]($RATE * $sec)
$b = Get-BrownNoise $sec 0.20
$s = New-Object 'double[]' $n
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $RATE
    $fadeIn = [math]::Min($t * 300.0, 1.0)
    $s[$i] = (0.5 * $b[$i] + 0.35 * [math]::Sin(2 * [math]::PI * 1500 * $t) + 0.25 * [math]::Sin(2 * [math]::PI * 2300 * $t)) * [math]::Exp(-$t / 0.06) * $fadeIn
}
Save-Wav (Join-Path $OUT 'scrape.wav') $s

# --- pickup: two-note coin ding ---
$sec = 0.28; $n = [int]($RATE * $sec); $s = New-Object 'double[]' $n
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $RATE
    if ($t -lt 0.14) { $f = 660.0; $a = $t / 0.02; if ($a -gt 1) { $a = 1 } } else { $f = 990.0; $a = 1.0 }
    $rel = ($sec - $t) / 0.07; if ($rel -lt 1) { $a *= $rel }
    $s[$i] = $a * [math]::Sin(2 * [math]::PI * $f * $t)
}
Save-Wav (Join-Path $OUT 'pickup.wav') $s

# --- refuel: soft pulsing hiss-loop ---
$sec = 1.0; $n = [int]($RATE * $sec); $s = New-Object 'double[]' $n
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $RATE
    $fade = [math]::Min($t * 40.0, [math]::Min((($sec - $t) * 40.0), 1.0))
    $s[$i] = (0.45 * [math]::Sin(2 * [math]::PI * 460 * $t) + 0.10 * [math]::Sin(2 * [math]::PI * 2310 * $t)) * (0.75 + 0.25 * [math]::Sin(2 * [math]::PI * 8 * $t)) * $fade
}
Save-Wav (Join-Path $OUT 'refuel.wav') $s

# --- lowfuel: short beep ---
$sec = 0.16; $n = [int]($RATE * $sec); $s = New-Object 'double[]' $n
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $RATE
    $a = [math]::Min($t / 0.008, 1.0) * [math]::Min((($sec - $t) / 0.04), 1.0)
    $s[$i] = $a * (0.6 * [math]::Sin(2 * [math]::PI * 440 * $t) + 0.25 * [math]::Sin(2 * [math]::PI * 1320 * $t))
}
Save-Wav (Join-Path $OUT 'lowfuel.wav') $s

# --- outoffuel: descending two-tone ---
$sec = 0.45; $n = [int]($RATE * $sec); $s = New-Object 'double[]' $n
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $RATE
    $a = [math]::Min($t / 0.02, 1.0) * [math]::Min((($sec - $t) / 0.10), 1.0)
    $phase = 2 * [math]::PI * (880 * $t - 220 * $t * $t)
    $s[$i] = $a * 0.5 * [math]::Sin($phase)
}
Save-Wav (Join-Path $OUT 'outoffuel.wav') $s

# --- wreck: heavy multi-decal crash ---
$sec = 0.7; $n = [int]($RATE * $sec)
$b = Get-BrownNoise $sec 0.28
$s = New-Object 'double[]' $n
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $RATE
    $s[$i] = 1.0 * $b[$i] * [math]::Exp(-$t / 0.22) + 0.6 * [math]::Sin(2 * [math]::PI * 80 * $t) * [math]::Exp(-$t / 0.18)
}
Save-Wav (Join-Path $OUT 'wreck.wav') $s

# --- restart: upward whoosh ---
$sec = 0.18; $n = [int]($RATE * $sec); $s = New-Object 'double[]' $n
for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $RATE
    $a = [math]::Min($t / 0.01, 1.0) * [math]::Min((($sec - $t) / 0.05), 1.0)
    $phase = 2 * [math]::PI * (240 * $t + 430 * $t * $t)
    $s[$i] = $a * 0.8 * [math]::Sin($phase)
}
Save-Wav (Join-Path $OUT 'restart.wav') $s

Get-ChildItem $OUT | Format-Table Name, Length -AutoSize