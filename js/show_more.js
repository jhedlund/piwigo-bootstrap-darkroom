/* "Show more" for visitors (guest_simplified_nav): replaces the numbered photo pagination with a
   button that appends the next page's tiles in place. The numbered pagination stays in the markup
   as the no-JS fallback. Listeners of 'bd:tiles-appended' (PhotoSwipe openers, select mode) pick
   the new tiles up; their data-index is album-wide, so the lightbox opens at the right photo. */
$(function() {
    var $pager = $('nav.bd-pager');
    var $grid = $('#thumbnails');
    var next = $pager.attr('data-bd-next');
    if ($pager.length !== 1 || !$grid.length || !next) return;
    /* Deep link to a later page: "show more" could never reach the earlier ones, keep the numbers. */
    if ($pager.find('a[rel="prev"]').length) return;

    var label = 'Show more photos';
    var $wrap = $('<div class="bd-show-more"><button type="button" class="btn bd-show-more-btn"></button></div>');
    var $btn = $wrap.find('button').text(label);
    $pager.addClass('d-none').after($wrap);

    var loading = false;
    $btn.on('click', function() {
        if (loading) return;
        loading = true;
        $btn.prop('disabled', true).text('Loading…');
        $.ajax({ url: next, dataType: 'html' }).done(function(html) {
            var doc = new DOMParser().parseFromString(html, 'text/html');
            var $tiles = $(doc).find('#thumbnails > .col-outer');
            if (!$tiles.length) {
                window.location.href = next;
                return;
            }
            /* Uncached derivatives come as a placeholder + data-src for the core loader, which only
               scans at page load; the data-src URL generates the derivative on a plain GET. */
            $tiles.find('img[data-src]').each(function() {
                this.setAttribute('src', this.getAttribute('data-src'));
                this.removeAttribute('data-src');
            });
            $grid.append($tiles);
            next = $(doc).find('nav.bd-pager').attr('data-bd-next');
            $(document).trigger('bd:tiles-appended', [$tiles]);
            if (next) {
                loading = false;
                $btn.prop('disabled', false).text(label);
            } else {
                $wrap.remove();
            }
        }).fail(function() {
            /* Fall back to the real next page rather than a dead button. */
            window.location.href = next;
        });
    });
});
