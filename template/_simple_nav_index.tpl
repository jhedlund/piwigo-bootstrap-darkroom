<!-- Start of _simple_nav_index.tpl -->
{* Visitor contextual bar (guest_simplified_nav): the current album always visible, no hidden menu,
   only the actions a visitor wants. Element ids match index.tpl's so the existing handlers bind. *}
    <nav class="navbar navbar-contextual bd-simple-nav {$theme_config->navbar_contextual_style} {$theme_config->navbar_contextual_bg} sticky-top mb-2">
        <div class="container{if $theme_config->fluid_width}-fluid{/if}">
            <div class="navbar-brand bd-crumbs">
{if isset($bd_crumb_last_name) && !isset($chronology.TITLE)}
{if isset($bd_crumb_parent_url)}
                <a class="bd-back d-lg-none" href="{$bd_crumb_parent_url}" title="{'Back'|@translate}" aria-label="{'Back'|@translate}"><i class="fas fa-chevron-left" aria-hidden="true"></i></a>
{/if}
                <span class="bd-current d-lg-none">{$bd_crumb_last_name}</span>
                <div class="nav-breadcrumb d-none d-lg-flex">{$TITLE}</div>
{elseif isset($chronology.TITLE)}
                <div class="nav-breadcrumb d-flex">{$chronology.TITLE}</div>
{else}
                <div class="nav-breadcrumb d-flex">{$TITLE}</div>
{/if}
            </div>
{assign var=bd_can_select value=$theme_config->photoswipe && !empty($THUMBNAILS) && !isset($GThumb) && !isset($GDThumb)}
{if isset($U_SLIDESHOW) || $bd_can_select || !empty($PLUGIN_INDEX_BUTTONS) || !empty($PLUGIN_INDEX_ACTIONS)}
            <ul class="navbar-nav flex-row bd-actions">
{if isset($U_SLIDESHOW)}
                <li class="nav-item">
                    <a class="nav-link" href="{if $theme_config->photoswipe}javascript:;{else}{$U_SLIDESHOW}{/if}" id="startSlideshow" title="{'slideshow'|@translate}" rel="nofollow">
                        <i class="fas fa-play fa-fw" aria-hidden="true"></i><span class="bd-label text-capitalize">{'slideshow'|@translate}</span>
                    </a>
                </li>
{/if}
{if !empty($PLUGIN_INDEX_BUTTONS)}{foreach from=$PLUGIN_INDEX_BUTTONS item=button}<li>{$button}</li>{/foreach}{/if}
{if !empty($PLUGIN_INDEX_ACTIONS)}{$PLUGIN_INDEX_ACTIONS}{/if}
{if $bd_can_select}
                <li id="btn-select" class="nav-item">
                    <a class="nav-link" href="javascript:;" title="Select photos to download">
                        <i class="far fa-check-square fa-fw" aria-hidden="true"></i><span class="bd-label">Select photos to download</span>
                    </a>
                </li>
{/if}
            </ul>
{/if}
        </div>
    </nav>
<!-- End of _simple_nav_index.tpl -->
