<!-- Start of _simple_nav_picture.tpl -->
{* Visitor contextual bar on the photo page (guest_simplified_nav): a back link to the album and
   labeled Slideshow / Download. The back link uses U_UP: it keeps share-link URLs and the album page
   the photo is on, where the breadcrumb links can be plain category URLs. Element ids match picture_nav.tpl's so the existing handlers bind. *}
<nav class="navbar navbar-contextual bd-simple-nav {$theme_config->navbar_contextual_style} {$theme_config->navbar_contextual_bg} sticky-top mb-2">
    <div class="container{if $theme_config->fluid_width}-fluid{/if}">
        <div class="navbar-brand bd-crumbs">
{if isset($bd_crumb_last_name)}
            <a class="bd-back" href="{if isset($U_UP)}{$U_UP}{else}{$bd_crumb_last_url}{/if}" title="{'Back'|@translate}"><i class="fas fa-chevron-left" aria-hidden="true"></i><span class="bd-current">{$bd_crumb_last_name}</span></a>
{else}
            <div class="nav-breadcrumb d-inline-flex">{$SECTION_TITLE}<span class="nav-breadcrumb-item active">{$current.TITLE}</span></div>
{/if}
        </div>
        <ul class="navbar-nav flex-row bd-actions">
{if isset($U_SLIDESHOW_START)}
            <li class="nav-item">
                <a class="nav-link" href="{if $theme_config->photoswipe}javascript:;{else}{$U_SLIDESHOW_START}{/if}" title="{'slideshow'|@translate}" id="startSlideshow" rel="nofollow">
                    <i class="fas fa-play fa-fw" aria-hidden="true"></i><span class="bd-label text-capitalize">{'slideshow'|@translate}</span>
                </a>
            </li>
{/if}
{if isset($current.U_DOWNLOAD)}
{if empty($current.formats)}
            <li class="nav-item">
                <a id="downloadSwitchLink" class="nav-link" href="{$current.U_DOWNLOAD}" title="{'Download this file'|@translate}" rel="nofollow">
                    <i class="fas fa-download fa-fw" aria-hidden="true"></i><span class="bd-label text-capitalize">{'Download'|@translate}</span>
                </a>
            </li>
{else}
            <li class="nav-item dropdown">
                <a href="#" class="nav-link dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" title="{'Download this file'|@translate}">
                    <i class="fas fa-download fa-fw" aria-hidden="true"></i><span class="bd-label text-capitalize">{'Download'|@translate}</span>
                </a>
                <ul class="dropdown-menu dropdown-menu-right" role="menu">
{foreach from=$current.formats item=format}
                    <li class="dropdown-item"><a href="{$format.download_url}" rel="nofollow">{$format.label}<span class="downloadformatDetails"> ({$format.filesize})</span></a></li>
{/foreach}
                </ul>
            </li>
{/if}
{/if}
{if isset($PLUGIN_PICTURE_BUTTONS)}{foreach from=$PLUGIN_PICTURE_BUTTONS item=button}{$button}{/foreach}{/if}
{if isset($PLUGIN_PICTURE_ACTIONS)}{$PLUGIN_PICTURE_ACTIONS}{/if}
        </ul>
    </div>
</nav>
<!-- End of _simple_nav_picture.tpl -->
