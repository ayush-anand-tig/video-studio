#!/bin/sh
# License-free music bed and UI sound effects, synthesized by ffmpeg from plain sine waves
# and seeded noise. Nothing is sampled, so there's nothing to license. This is the zero-setup
# fallback for music, as `say` is for voice: plain, unobtrusive, always available, and
# deterministic (same arguments, same file).
#
# Usage (run from projects/<slug>/):
#   synth-audio.sh bed <seconds> <calm|cinematic|energetic> <out.wav>
#       A soft chord pad that crossfades through four chords, with a fade in/out. It plugs
#       into Phase 3's mix as audio/music.wav, already the right length.
#   synth-audio.sh sfx <spots.txt> <seconds> <out.wav>
#       Places one-shots on one track. spots.txt has one per line: "<beat> <offset> <sound>",
#       e.g. "cause 0.4 click". Times resolve through src/cues.json, so a retime moves the
#       sounds with their beats. Sounds: tick, click, pop, whoosh. '#' starts a comment.
set -eu

die() { echo "$*" >&2; exit 1; }

one_shot() {  # <sound> <out.wav>
  case "$1" in
    tick)   e='0.5*sin(2*PI*2400*t)*exp(-t*90)'; d=0.08; f=anull ;;
    click)  e='(0.3*(random(0)*2-1)+0.2*sin(2*PI*1500*t))*exp(-t*260)'; d=0.05; f='highpass=f=900' ;;
    pop)    e='0.5*sin(2*PI*(500*t+1500*t*t))*exp(-t*28)'; d=0.2; f=anull ;;
    whoosh) e='0.6*(random(0)*2-1)*pow(sin(PI*t/0.6),2)'; d=0.6; f='highpass=f=300,lowpass=f=2800' ;;
    *) die "Unknown sound '$1'. Use tick, click, pop or whoosh." ;;
  esac
  ffmpeg -v error -y -f lavfi -i "aevalsrc=exprs='$e':s=48000:d=$d" -af "$f" "$2"
}

case "${1:-}" in
  bed)
    DUR="${2:?Usage: synth-audio.sh bed <seconds> <calm|cinematic|energetic> <out.wav>}"
    MOOD="${3:?Usage: synth-audio.sh bed <seconds> <calm|cinematic|energetic> <out.wav>}"
    OUT="${4:?Usage: synth-audio.sh bed <seconds> <calm|cinematic|energetic> <out.wav>}"
    # Four chords (Hz, low to high) and seconds per chord. extra = post-filter for character.
    case "$MOOD" in
      calm)      D=4; extra=anull
                 C="130.81 196.00 246.94 329.63|110.00 164.81 196.00 261.63|87.31 130.81 164.81 220.00|98.00 146.83 246.94 329.63" ;;
      cinematic) D=6; extra=anull
                 C="110.00 164.81 220.00 261.63|87.31 130.81 174.61 220.00|130.81 196.00 261.63 329.63|98.00 146.83 196.00 246.94" ;;
      energetic) D=2; extra='tremolo=f=4:d=0.3'
                 C="146.83 220.00 293.66 369.99|110.00 164.81 220.00 277.18|123.47 185.00 246.94 293.66|98.00 146.83 196.00 246.94" ;;
      *) die "Unknown mood '$MOOD'. Use calm, cinematic or energetic." ;;
    esac
    # Each chord fades in and out on a raised-cosine window; neighbouring windows overlap so
    # they always sum to 1 (smooth changes, steady level). The right channel is detuned 0.4%
    # against the left for width.
    P=$((4 * D)); L=""; R=""; k=0
    IFS='|'; for chord in $C; do
      w="if(lt(abs(mod(t-$((k * D))+$((2 * D + P)),$P)-$((2 * D))),$D),0.5+0.5*cos(PI*(mod(t-$((k * D))+$((2 * D + P)),$P)-$((2 * D)))/$D),0)"
      IFS=' '; sl=""; sr=""
      for f in $chord; do sl="$sl+sin(2*PI*$f*t)"; sr="$sr+sin(2*PI*$f*1.004*t)"; done
      L="$L+$w*(${sl#+})"; R="$R+$w*(${sr#+})"; k=$((k + 1)); IFS='|'
    done; unset IFS
    [ "$(echo "$DUR >= 4" | bc)" = 1 ] || die "A bed needs at least 4 s (it fades in and out)."
    out_at=$(echo "$DUR - 2" | bc)
    ffmpeg -v error -y -f lavfi -i "aevalsrc=exprs='0.18*(${L#+})|0.18*(${R#+})':s=16000:d=$DUR" \
      -af "lowpass=f=1800,aecho=0.8:0.6:90|170:0.25|0.15,$extra,afade=t=in:d=1.5,afade=t=out:st=$out_at:d=2" \
      -ar 48000 "$OUT"
    echo "synthesized bed ($MOOD, ${DUR}s) -> $OUT"
    ;;
  sfx)
    SPOTS="${2:?Usage: synth-audio.sh sfx <spots.txt> <seconds> <out.wav>}"
    DUR="${3:?Usage: synth-audio.sh sfx <spots.txt> <seconds> <out.wav>}"
    OUT="${4:?Usage: synth-audio.sh sfx <spots.txt> <seconds> <out.wav>}"
    [ -f "$SPOTS" ] || die "No such file: $SPOTS"
    [ -f src/cues.json ] || die "Needs src/cues.json (run from projects/<slug>/ after Phase 2)."
    W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
    n=0; args=""; graph=""; mixin=""
    while read -r beat off sound _; do
      case "$beat" in ''|\#*) continue ;; esac
      [ -n "${sound:-}" ] || die "Bad line '$beat $off': use '<beat> <offset> <sound>'."
      t0=$(jq -r --arg b "$beat" '.[$b] // empty' src/cues.json)
      [ -n "$t0" ] || die "No beat '$beat' in src/cues.json."
      [ -f "$W/$sound.wav" ] || one_shot "$sound" "$W/$sound.wav"
      ms=$(echo "($t0 + ($off)) * 1000 / 1" | bc); [ "$ms" -lt 0 ] && ms=0
      args="$args $W/$sound.wav"; graph="$graph[$n:a]adelay=$ms:all=1[s$n];"; mixin="$mixin[s$n]"
      n=$((n + 1))
    done < "$SPOTS"
    [ "$n" -gt 0 ] || die "No sounds spotted in $SPOTS."
    inputs=""; for a in $args; do inputs="$inputs -i $a"; done
    # shellcheck disable=SC2086
    ffmpeg -v error -y $inputs -filter_complex "${graph}${mixin}amix=inputs=$n:normalize=0,apad,atrim=end=$DUR" -ar 48000 "$OUT"
    echo "placed $n sound(s) -> $OUT"
    ;;
  *) die "Usage: synth-audio.sh bed <seconds> <mood> <out.wav> | sfx <spots.txt> <seconds> <out.wav>" ;;
esac
