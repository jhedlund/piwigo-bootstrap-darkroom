{footer_script require='jquery'}{strip}
/* Album select mode: pick photos on this page, download them in one go. Selection lives in page
   JS only, so pagination (full page loads) drops it by design. Videos are excluded. */
$(function() {
    var $bar = $('#multi-dl-bar');
    if (!$bar.length) return;
    var CEILING = 20;
    var $count = $bar.find('.multi-dl-count');
    var $go = $bar.find('.multi-dl-go');
    var $goLabel = $bar.find('.multi-dl-go-label');
    var $fill = $bar.find('.multi-dl-progress__fill');
    var $data = $('#photoSwipeData a');
    var selecting = false;
    var busy = false;
    var selected = [];
    var shareFiles = null;
    var gen = 0;
    var noteTimer = null;
    var cap = 0;

    var cards = function() {
        return $('#thumbnails .card-thumbnail');
    };
    /* #photoSwipeData covers the whole album, not just this page; a card's data-index (offset by
       START_ID) is its position in that list. */
    var imageidOf = function($card) {
        var idx = $card.find('a[data-index]').first().attr('data-index');
        var $d = idx === undefined ? $() : $data.filter('[data-index="' + idx + '"]');
        if (!$d.length || $d.attr('data-video')) return null;
        return $d.data('src-imageid');
    };
    var nameOf = function(imageid) {
        return $data.filter('[data-src-imageid="' + imageid + '"]').data('name');
    };

    var render = function() {
        if (!noteTimer) $count.text(selected.length + ' of ' + cap);
        $go.prop('disabled', !selected.length);
        $go.toggleClass('ready', !!shareFiles);
        if (busy) return;
        $goLabel.text(shareFiles ? 'Tap to save ' + shareFiles.length : 'Download');
    };
    var note = function(msg) {
        clearTimeout(noteTimer);
        $count.text(msg).addClass('flash');
        noteTimer = setTimeout(function() {
            noteTimer = null;
            $count.removeClass('flash');
            render();
        }, 1600);
    };
    var setProgress = function(fraction) {
        $bar.toggleClass('loading', fraction !== null);
        $fill.css('width', fraction === null ? '0%' : Math.min(100, fraction * 100) + '%');
    };
    /* Any selection change makes a cached share batch stale. */
    var dropCache = function() {
        shareFiles = null;
        setProgress(null);
    };

    var toggle = function($card) {
        if (busy) { note('Preparing download…'); return; }
        var id = imageidOf($card);
        if (id === null || id === undefined) { note('No videos in a batch'); return; }
        var i = selected.indexOf(id);
        if (i >= 0) {
            selected.splice(i, 1);
            $card.removeClass('selected');
        } else if (selected.length >= cap) {
            note('Max ' + cap + ' per batch');
            return;
        } else {
            selected.push(id);
            $card.addClass('selected');
        }
        dropCache();
        render();
    };
    var selectAll = function() {
        if (busy) return;
        var selectable = cards().filter(function() {
            var id = imageidOf($(this));
            return id !== null && id !== undefined;
        }).slice(0, cap);
        var allOn = selected.length === selectable.length;
        selected = [];
        cards().removeClass('selected');
        if (!allOn) {
            selectable.each(function() {
                selected.push(imageidOf($(this)));
                $(this).addClass('selected');
            });
        }
        dropCache();
        render();
    };

    var enter = function() {
        selecting = true;
        cap = 0;
        cards().each(function() {
            var id = imageidOf($(this));
            var on = id !== null && id !== undefined;
            $(this).toggleClass('multi-dl-off', !on);
            if (on) cap++;
        });
        cap = Math.min(cap, CEILING);
        $('body').addClass('multi-select');
        $('#btn-select').addClass('active');
        $('#secondary-navbar.show').collapse('hide');
        render();
    };
    var exit = function() {
        gen++;
        selecting = false;
        busy = false;
        selected = [];
        dropCache();
        clearTimeout(noteTimer);
        noteTimer = null;
        $count.removeClass('flash');
        cards().removeClass('selected multi-dl-off');
        $('body').removeClass('multi-select');
        $('#btn-select').removeClass('active');
    };

    var directDownloads = function(ids) {
        /* Spaced out so Chrome raises its "download multiple files" prompt once and lets the rest through. */
        ids.forEach(function(id, i) {
            setTimeout(function() { dlFallbackDownload(id); }, i * 300);
        });
    };

    var shareCached = function() {
        var files = shareFiles;
        /* Second tap: files already in memory, so share() runs synchronously inside the gesture. */
        navigator.share({ files: files }).then(exit).catch(function(err) {
            /* Keep the cache on cancel so another tap opens the sheet instantly. */
            if (!err || err.name !== 'AbortError') {
                var ids = selected.slice();
                exit();
                directDownloads(ids);
            }
        });
    };

    var download = function() {
        if (busy || !selected.length) return;
        var ids = selected.slice();
        /* iOS only, as in the lightbox: its share sheet saves to Photos; elsewhere the browser's own
           download manager is the right destination. */
        if (!dlIsIOS() || typeof navigator.canShare !== 'function') {
            exit();
            directDownloads(ids);
            return;
        }
        if (shareFiles) { shareCached(); return; }
        var myGen = gen;
        var files = [];
        busy = true;
        $go.addClass('busy');
        setProgress(0);
        var fetchNext = function(i) {
            if (i >= ids.length) return Promise.resolve();
            $goLabel.text('Preparing ' + (i + 1) + ' of ' + ids.length + '…');
            return dlFetchOriginal(ids[i], nameOf(ids[i]), function(received, total) {
                if (myGen === gen) setProgress((i + (total ? received / total : 0)) / ids.length);
            }).then(function(file) {
                files.push(file);
                return fetchNext(i + 1);
            });
        };
        fetchNext(0).then(function() {
            if (myGen !== gen) return;
            if (!navigator.canShare({ files: files })) { throw new Error('files not shareable'); }
            return navigator.share({ files: files }).then(function() {
                if (myGen === gen) exit();
            }, function(err) {
                if (err && err.name === 'NotAllowedError') {
                    /* The tap's user activation expired during the fetches. Cache the batch and ask
                       for one more tap, which can call share() synchronously. */
                    if (myGen === gen) shareFiles = files;
                    return;
                }
                throw err;
            });
        }).catch(function(err) {
            if (myGen !== gen || (err && err.name === 'AbortError')) return;
            /* Any failure degrades the whole batch to plain downloads rather than a partial mix. */
            exit();
            directDownloads(ids);
        }).finally(function() {
            if (myGen !== gen) return;
            busy = false;
            $go.removeClass('busy');
            setProgress(shareFiles ? 1 : null);
            render();
        });
    };

    /* Capture phase: the thumbnail links carry their own click/tap handlers (PhotoSwipe opener, or a
       plain link), which a delegated handler would reach too late. jQuery-Touch-Events fires tap from
       touchend/mouseup, so those are swallowed too and the following click does the toggling. */
    var intercept = function(e) {
        if (!selecting) return;
        var $card = $(e.target).closest('#thumbnails .card-thumbnail');
        if (!$card.length) return;
        e.stopPropagation();
        if (e.type !== 'click') return;
        e.preventDefault();
        toggle($card);
    };
    ['click', 'touchend', 'mouseup'].forEach(function(type) {
        document.addEventListener(type, intercept, true);
    });

    $('#btn-select a').on('click', function(e) {
        e.preventDefault();
        if (selecting) { exit(); } else { enter(); }
    });
    $bar.find('.multi-dl-all').on('click', selectAll);
    $bar.find('.multi-dl-close').on('click', exit);
    $go.on('click', download);
});
{/strip}{/footer_script}
