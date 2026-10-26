/* Justified photo rows (justified_grid): every photo at its true aspect ratio, in even-height rows.
   The server renders the ordinary column grid with uncropped images and data-w/data-h on each tile;
   this sizes those tiles in place. No wrappers, no moved or cloned nodes, so the PhotoSwipe openers
   and select mode keep their bindings. #thumbnails.bd-justified stays hidden until the first layout
   (css/justified.css) so the column grid never flashes. */
$(function() {
    var grid = document.getElementById('thumbnails');
    if (!grid || !$(grid).hasClass('bd-justified')) return;
    var GAP = 6;
    var lastWidth = 0;

    var targetHeight = function() {
        return window.innerWidth < 576 ? 160 : 300;
    };
    var tiles = function() {
        return $(grid).children('.col-outer').get();
    };
    var ratio = function(tile) {
        var w = +tile.getAttribute('data-w'), h = +tile.getAttribute('data-h');
        return w > 0 && h > 0 ? w / h : 1.5;
    };
    var size = function(tile, w, h) {
        tile.style.width = w ? w + 'px' : '';
        tile.style.flex = w ? '0 0 ' + w + 'px' : '';
        tile.style.maxWidth = w ? 'none' : '';
        $(tile).find('img.thumb-img').css('height', h ? h + 'px' : '');
    };

    var clear = function() {
        grid.classList.remove('bd-justified-on');
        tiles().forEach(function(tile) { size(tile, 0, 0); });
    };

    var layout = function() {
        try {
            /* The grid/list buttons switch views without a reload; list view keeps its own layout. */
            if (!$('#content').hasClass('content-grid')) {
                clear();
                return;
            }
            grid.classList.add('bd-justified-on');
            var W = grid.clientWidth;
            var H = targetHeight();
            var all = tiles();
            var i = 0;
            lastWidth = W;
            while (i < all.length) {
                var row = [], sum = 0;
                while (i < all.length) {
                    row.push(all[i]);
                    sum += ratio(all[i]);
                    i++;
                    if (sum * H + (row.length - 1) * GAP >= W) break;
                }
                var gaps = (row.length - 1) * GAP;
                var full = sum * H + gaps >= W;
                /* A full row is scaled to the exact width; the sparse last row keeps the target height. */
                var h = full ? (W - gaps) / sum : H;
                h = Math.min(h, H * 1.5);
                row.forEach(function(tile, k) {
                    /* Rounded down so a full row never sums past W and wraps; the last tile gives up a
                       hundredth of a pixel to absorb floating-point error. */
                    var w = Math.floor(ratio(tile) * h * 100) / 100;
                    if (full && k === row.length - 1) w -= 0.01;
                    size(tile, w, Math.round(h * 100) / 100);
                });
            }
        } finally {
            grid.classList.add('bd-justified-ready');
        }
    };

    /* Width changes, including a scrollbar appearing once the rows settle (no window resize event). */
    var timer = null;
    var relayoutSoon = function() {
        clearTimeout(timer);
        timer = setTimeout(function() {
            if (grid.clientWidth !== lastWidth) layout();
        }, 150);
    };
    if (window.ResizeObserver) {
        new ResizeObserver(relayoutSoon).observe(grid);
    } else {
        $(window).on('resize', relayoutSoon);
    }
    $(document).on('bd:tiles-appended', layout);
    $('#btn-grid, #btn-list').on('click', function() {
        setTimeout(layout, 0);
    });
    layout();
});
