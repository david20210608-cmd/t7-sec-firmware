#!/bin/sh
# t7: build-time patches for Handshake Snooper attack.sh (path contains a
# space, so quilt patches cannot be used; the sed programs also cannot live
# inline in the Makefile - define bodies go through make's double $-expansion
# and bare $$/$@/$# get eaten). Usage: sh patch-handshake-snooper.sh <pkg-build-dir>
f="$1/attacks/Handshake Snooper/attack.sh"
[ -f "$f" ] || exit 1
# hcxpcapngtool verifier: menu entry (shown only if the binary exists) + case branch
sed -i 's#^  choices.=(..FLUXIONGeneralBackOption.)$#  if [ -x "$(command -v hcxpcapngtool)" ]; then\n    choices+=("hash - hcxpcapngtool (SAE/WPA3)")\n  fi\n&#' "$f"
sed -i 's#^      HandshakeSnooperVerifierIdentifier="cowpatty" ;;$#&\n    "hash - hcxpcapngtool (SAE/WPA3)")\n      HandshakeSnooperVerifierIdentifier="hcxpcapngtool" ;;#' "$f"
# PMF hint: SAE targets drop forged deauth; pmf-detect warns from the airodump CSV
sed -i 's@^  handshake_snooper_start_deauthenticator$@&\n  # t7: WPA3/SAE targets enforce 802.11w PMF; forged deauth is dropped.\n  ( sleep 10; pmf-detect "$FLUXIONWorkspacePath/capture/dump-01.csv" "$FluxionTargetMAC" >> "$FLUXIONWorkspacePath/handshake_snooper.log" 2>\&1 ) \&@' "$f"
# t7: heal wedged 5G monitor at each captor restart (snippet file keeps the
# awk program free of sed &/$ escaping). Insert before start_captor's first
# "local parentPID" (function handshake_snooper_start_captor).
awk -v t="$(dirname "$0")/hs-mon-heal.snippet" '
  BEGIN{while((getline l < t)>0) ins=ins l ORS}
  !done && /^  local parentPID$/{printf "%s", ins; done=1}
  {print}' "$f" > "$f.new" && mv "$f.new" "$f"
