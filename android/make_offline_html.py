"""Turn game/index.html (CDN three.js + Google Fonts) into one offline HTML file for the APK.
Usage: python3 make_offline_html.py ../game/index.html out/index.html  (needs npm and curl)"""
import base64, os, re, subprocess, sys
src, out = sys.argv[1], sys.argv[2]
work = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build-cache', 'bundle'); os.makedirs(work, exist_ok=True)
s = open(src).read()
i = s.index('<script type="module">') + len('<script type="module">'); j = s.index('</script>', i)
open(os.path.join(work, 'game.js'), 'w').write(s[i:j].replace("from 'three/addons/utils/BufferGeometryUtils.js'", "from 'three/examples/jsm/utils/BufferGeometryUtils.js'"))
if not os.path.exists(os.path.join(work, 'node_modules', 'peerjs')):
    subprocess.run(['npm', 'init', '-y'], cwd=work, check=True, capture_output=True)
    subprocess.run(['npm', 'install', 'three@0.160.0', 'peerjs@1.5.4', 'esbuild@0.21.5'], cwd=work, check=True)
subprocess.run(['npx', 'esbuild', 'game.js', '--bundle', '--minify', '--format=iife', '--target=es2019', '--outfile=game.bundle.js'], cwd=work, check=True)
js = open(os.path.join(work, 'game.bundle.js')).read().replace('</script', '<\\/script')
ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
href = re.search(r'<link rel="stylesheet" href="(https://fonts.googleapis.com[^"]+)"', s).group(1).replace('&amp;', '&')
css = subprocess.run(['curl', '-sS', '-A', ua, href], check=True, capture_output=True, text=True).stdout
faces = []
for b in re.findall(r'/\* latin \*/\s*(@font-face\s*\{[^}]*\})', css):
    url = re.search(r'url\((https://[^)]+)\)', b).group(1)
    data = subprocess.run(['curl', '-sS', url], check=True, capture_output=True).stdout
    faces.append(b.replace(url, 'data:font/woff2;base64,' + base64.b64encode(data).decode()))
page = s[:s.index('<script type="importmap">')] + '<script>\n' + js + '\n</script>' + s[j + len('</script>'):]
page = re.sub(r'<link rel="preconnect"[^>]*>\n?', '', page)
page = re.sub(r'<link rel="stylesheet" href="https://fonts.googleapis.com[^>]*>\n?', '', page)
page = page.replace('<style>', '<style>\n' + '\n'.join(faces) + '\n', 1)
for tag in ['<!doctype html>', '<html lang="te">', '<head>', '</head>', '<body>', '</body>', '</html>']:
    page = page.replace(tag, '')
page = '<!doctype html>\n<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">\n' + page.replace('<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">', '') + '\n</body></html>'
open(out, 'w').write(page)
print('wrote', out, len(page) // 1024, 'KB')
