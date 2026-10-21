{footer_script require='jquery'}{strip}
/* Original-file download primitives shared by the lightbox button and album multi-select. No UI here. */
function dlOriginalUrl(imageid) {
    return "{$ROOT_URL}action.php?id=" + imageid + "&part=e&download";
}

function dlIsIOS() {
    var ua = navigator.userAgent;
    return /iPad|iPhone|iPod/.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1);
}

function dlFallbackDownload(imageid) {
    var link = document.createElement("a");
    link.href = dlOriginalUrl(imageid);
    link.click();
}

/* Resolves to a File of the original. onProgress(received, total) runs once before the first chunk
   and after each one; total 0 = size unknown. name is the filename stem when the server sends none. */
function dlFetchOriginal(imageid, name, onProgress) {
    var progress = onProgress || function() { };
    return fetch(dlOriginalUrl(imageid), { credentials: 'same-origin' }).then(function(resp) {
        if (!resp.ok) { throw new Error('HTTP ' + resp.status); }
        var cd = resp.headers.get('Content-Disposition') || '';
        var m = cd.match(/filename="?([^";]+)"?/);
        var ctype = resp.headers.get('Content-Type') || 'image/jpeg';
        var total = parseInt(resp.headers.get('Content-Length'), 10) || 0;
        var readBlob;
        if (resp.body && resp.body.getReader) {
            progress(0, total);
            var reader = resp.body.getReader();
            var chunks = [];
            var received = 0;
            readBlob = function next() {
                return reader.read().then(function(r) {
                    if (r.done) { return new Blob(chunks, { type: ctype }); }
                    chunks.push(r.value);
                    received += r.value.length;
                    progress(received, total);
                    return next();
                });
            }();
        } else {
            /* No streaming support: plain blob, progress unknown. */
            progress(0, 0);
            readBlob = resp.blob();
        }
        return readBlob.then(function(blob) {
            var ext = (blob.type.split('/')[1] || 'jpg').replace('jpeg', 'jpg');
            var fname = m ? m[1] : ((name || 'photo') + '.' + ext);
            return new File([blob], fname, { type: blob.type });
        });
    });
}
{/strip}{/footer_script}
