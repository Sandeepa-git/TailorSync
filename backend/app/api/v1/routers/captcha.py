"""reCAPTCHA support for the mobile/web app.

/auth/captcha-config  -> tells the app whether reCAPTCHA is turned on
/auth/captcha-page    -> page with Google's widget, shown in a WebView / iframe.
Because the page is served from this API's domain, add that domain in the
reCAPTCHA admin console (google.com/recaptcha/admin).
"""
import html

from fastapi import APIRouter
from fastapi.responses import HTMLResponse

from app.services import recaptcha_service

router = APIRouter()

_PAGE = """<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  html, body { margin:0; padding:0; background:transparent; overflow:hidden; scrollbar-width:none; }
  ::-webkit-scrollbar { display:none; }
  #box { padding:1px 0 0 1px; transform-origin:0 0; }
</style>
<script src="https://www.google.com/recaptcha/api.js" async defer></script>
</head>
<body>
<div id="box">
  <div class="g-recaptcha" data-sitekey="__SITE_KEY__"
       data-callback="onOk" data-expired-callback="onExpired" data-error-callback="onErr"></div>
</div>
<script>
  function send(m) {
    if (window.CaptchaChannel) { try { CaptchaChannel.postMessage(m); } catch (e) {} return; }
    if (window.parent && window.parent !== window) { window.parent.postMessage('captcha|' + m, '*'); }
  }
  function onOk(token) { send('token:' + token); }
  function onExpired() { send('expired'); }
  function onErr() { send('error:network'); }

  // Shrink the 304px checkbox on narrow screens.
  var boxScale = Math.min(1, (window.innerWidth - 2) / 304);
  document.getElementById('box').style.transform = 'scale(' + boxScale + ')';

  // When Google opens an image challenge, fit it into the frame and tell the
  // app how tall the frame must be so it can grow in place.
  var lastH = 0;
  function report() {
    var box = document.getElementById('box').getBoundingClientRect();
    var h = Math.max(Math.ceil(80 * boxScale), Math.ceil(box.bottom) + 4);
    var frames = document.querySelectorAll('iframe[src*="bframe"]');
    for (var i = 0; i < frames.length; i++) {
      var c = frames[i].parentNode && frames[i].parentNode.parentNode;
      if (c && c.style && c.style.visibility === 'visible') {
        var s = Math.min(1, (window.innerWidth - 4) / 400);
        c.style.transformOrigin = '0 0';
        c.style.transform = 'scale(' + s + ')';
        c.style.left = '2px';
        c.style.top = '2px';
        h = Math.max(h, Math.ceil(590 * s) + 8);
      }
    }
    if (h !== lastH) { lastH = h; send('height:' + h); }
  }
  setInterval(report, 300);
  send('ready');
</script>
</body>
</html>"""


@router.get("/captcha-config")
def captcha_config():
    return {"enabled": recaptcha_service.is_enabled(), "provider": "recaptcha-v2"}


@router.get("/captcha-page", response_class=HTMLResponse, include_in_schema=False)
def captcha_page():
    page = _PAGE.replace("__SITE_KEY__", html.escape(recaptcha_service.site_key()))
    return HTMLResponse(page, headers={"Cache-Control": "no-store"})
