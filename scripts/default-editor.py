"""Make one app the default for source and text files.

Filters the LaunchServices handler plist, stdin to stdout:

    defaults export com.apple.LaunchServices/com.apple.launchservices.secure - \
      | python3 -I default-editor.py dev.zed.Zed \
      | defaults import com.apple.LaunchServices/com.apple.launchservices.secure -

Each extension gets a handler for its type, as resolved by LaunchServices
now (installed apps can declare new ones, like org.go.source), and an
extension entry, which is what Finder's "Change All" writes for types that
have no registered identifier (.toml).
"""
import plistlib
import subprocess
import sys

EXTENSIONS = """
txt md markdown json jsonc yaml yml toml ini cfg conf env xml
py rb pl php lua r jl sh bash fish vim sql
js mjs cjs ts tsx jsx vue svelte css scss sass less
c h cc cpp cxx hpp m mm swift java kt kts scala go rs hs ex erl clj dart
make mk cmake gradle properties proto graphql gql tf nix diff patch lock
tex sty cls applescript dockerfile gitignore gitattributes editorconfig
""".split()

# Parents, for extensions not listed above.
BASE_TYPES = ["public.plain-text", "public.source-code", "public.script"]

RESOLVE = """
ObjC.import("CoreServices");
function run(exts) {
  return exts.map(e => ObjC.unwrap(ObjC.castRefToObject(
    $.UTTypeCreatePreferredIdentifierForTag(
      $.kUTTagClassFilenameExtension, $(e), null)))).join("\\n");
}
"""


def resolve_types(exts):
    out = subprocess.run(["osascript", "-l", "JavaScript", "-e", RESOLVE, *exts],
                         capture_output=True, text=True, check=True).stdout
    return [t for t in out.split() if not t.startswith("dyn.")]


def handler(app, **keys):
    return {**keys, "LSHandlerRoleAll": app,
            "LSHandlerPreferredVersions": {"LSHandlerRoleAll": "-"}}


def set_default(prefs, app, types, exts):
    types, exts = sorted(set(types)), sorted(set(exts))

    def replaced(h):
        return (h.get("LSHandlerContentType") in types
                or (h.get("LSHandlerContentTagClass") == "public.filename-extension"
                    and h.get("LSHandlerContentTag", "").lower() in exts))

    prefs["LSHandlers"] = (
        [h for h in prefs.get("LSHandlers", []) if not replaced(h)]
        + [handler(app, LSHandlerContentType=t) for t in types]
        + [handler(app, LSHandlerContentTag=e,
                   LSHandlerContentTagClass="public.filename-extension")
           for e in exts])
    return prefs


if __name__ == "__main__":
    prefs = plistlib.load(sys.stdin.buffer)
    types = BASE_TYPES + resolve_types(EXTENSIONS)
    plistlib.dump(set_default(prefs, sys.argv[1], types, EXTENSIONS), sys.stdout.buffer)
