<?php
namespace BootstrapDarkroom;

class ThemeController {
    private $config;

    public function __construct() {
        $this->config = new Config();
    }

    public function init() {
        load_language('theme.lang', PHPWG_THEMES_PATH.'bootstrap_darkroom/');
        load_language('lang', PHPWG_ROOT_PATH.PWG_LOCAL_DIR, array('no_fallback'=>true, 'local'=>true) );

        add_event_handler('init', array($this, 'assignConfig'));
        add_event_handler('init', array($this, 'setInitValues'));

        if ($this->config->bootstrap_theme === 'darkroom' || $this->config->bootstrap_theme === 'material' || $this->config->bootstrap_theme === 'bootswatch') {
          $this->config->bootstrap_theme = 'bootstrap-darkroom';
          $this->config->save();
          add_event_handler('loc_begin_page_header', array($this, 'showUpgradeWarning'));
        }

        $shortname = $this->config->comments_disqus_shortname;                                                                                                                 
        if ($this->config->comments_type == 'disqus' && !empty($shortname)) {                                                                                                  
            add_event_handler('blockmanager_apply', array($this, 'hideMenus'));                                                                                                
        }

        add_event_handler('loc_begin_page_header', array($this, 'checkIfHomepage'));
        add_event_handler('loc_after_page_header', array($this, 'stripBreadcrumbs'));
        add_event_handler('format_exif_data', array($this, 'exifReplacements'));
        add_event_handler('loc_end_picture', array($this, 'registerPictureTemplates'), 1000);
        add_event_handler('loc_begin_picture', array($this, 'setPictureDefaultSize'));
        // After plugins that rewrite breadcrumb URLs (UnlistedAlbum: neutral + 10), before
        // registerPictureTemplates renders picture_nav.tpl.
        add_event_handler('loc_end_index', array($this, 'assignBackLink'), EVENT_HANDLER_PRIORITY_NEUTRAL + 50);
        add_event_handler('loc_end_picture', array($this, 'assignBackLink'), 999);
        add_event_handler('loc_begin_index_thumbnails', array($this, 'returnPageStart'));

        if ($this->config->slick_enabled === true || $this->config->photoswipe === true) {
            add_event_handler('loc_end_picture', array($this, 'getAllThumbnailsInCategory'));
           // also needed on index.tpl for compatibility with GThumb+/GDThumb
           add_event_handler('loc_end_index', array($this, 'getAllThumbnailsInCategory'));
        }
    }

    public function assignConfig() {
        global $template, $conf;

        if (array_key_exists('bootstrap_darkroom_navbar_main_style', $conf) && !empty($conf['bootstrap_darkroom_navbar_main_style'])) {
            $this->config->navbar_main_style = $conf['bootstrap_darkroom_navbar_main_style'];
        }
        if (array_key_exists('bootstrap_darkroom_navbar_main_bg', $conf) && !empty($conf['bootstrap_darkroom_navbar_main_bg'])) {
            $this->config->navbar_main_bg = $conf['bootstrap_darkroom_navbar_main_bg'];
        }
        if (array_key_exists('bootstrap_darkroom_navbar_contextual_style', $conf) && !empty($conf['bootstrap_darkroom_navbar_contextual_style'])) {
            $this->config->navbar_contextual_style = $conf['bootstrap_darkroom_navbar_contextual_style'];
        }
        if (array_key_exists('bootstrap_darkroom_navbar_contextual_bg', $conf) && !empty($conf['bootstrap_darkroom_navbar_contextual_bg'])) {
            $this->config->navbar_contextual_bg = $conf['bootstrap_darkroom_navbar_contextual_bg'];
        }

        $template->assign('theme_config', $this->config);

        $simple = $this->isSimpleNav();
        if ($simple) {
            // Visitors have no grid/list buttons, so a list-view cookie left by a signed-in session in
            // the same browser would strand them in list view. Templates read $_COOKIE per request.
            unset($_COOKIE['view']);
        }
        $template->assign(array(
            'bd_simple_nav' => $simple,
            'bd_login_url' => $this->visitorLoginUrl(),
        ));
    }

    // Visitors always get a Login link. A ShareAlbum share identity is signed in, so it goes through
    // ShareAlbum's own switch (it logs the share user out, then opens the login page).
    private function visitorLoginUrl() {
        if (!is_a_guest() && defined('SHAREALBUM_URL_ACTION') && defined('SHAREALBUM_URL_ACTION_LOGIN')) {
            return get_root_url() . 'index.php?' . SHAREALBUM_URL_ACTION . '=' . SHAREALBUM_URL_ACTION_LOGIN;
        }
        return get_root_url() . 'identification.php';
    }

    public function showUpgradeWarning() {
        global $page;
        $page['errors'][] = l10n('Your selected color style has been reset to "bootstrap-darkroom". You can select a different color style in the admin section.');
    }

    public function hideMenus($menus) {
        $menu = &$menus[0];

        $mbMenu = $menu->get_block('mbMenu');
        unset($mbMenu->data['comments']);
    }

    // The visitor layer belongs to the Custom skin: nothing changes on deploy until Color theme ->
    // Custom is selected, and switching back is a complete rollback.
    private function isSimpleNav() {
        return $this->config->guest_simplified_nav
            && $this->config->bootstrap_theme === 'custom'
            && $this->isVisitor();
    }

    // Guests, plus ShareAlbum share-link visitors: that plugin logs them in as auto-created share_*
    // users. Every other signed-in account keeps the full controls.
    private function isVisitor() {
        global $user;

        if (is_a_guest()) {
            return true;
        }
        if (pwg_get_session_var('sharealbum_guest')) {
            return true;
        }
        return defined('SHAREALBUM_USER_PREFIX') && isset($user['username'])
            && strpos($user['username'], SHAREALBUM_USER_PREFIX) === 0;
    }

    // Piwigo's default photo-page size is medium (396x594 for a portrait), small and soft on a
    // desktop screen. Visitors have no photo sizes menu, so give them a sharp default instead.
    public function setPictureDefaultSize() {
        global $conf;

        if (!$this->isSimpleNav()) {
            return;
        }
        $type = get_device() == 'mobile' ? IMG_LARGE : IMG_XXLARGE;
        if (array_key_exists($type, \ImageStdParams::get_defined_type_map())) {
            $conf['derivative_default_size'] = $type;
        }
    }

    public function returnPageStart() {
        global $page, $template;

        $template->assign('START_ID', $page['start']);
    }

    public function checkIfHomepage() {
        global $template, $page;

        if (isset($page['is_homepage']) and $page['is_homepage']) {
            $template->assign('is_homepage', true);
        } else {
            $template->assign('is_homepage', false);
        }
    }

    public function setInitValues()
    {
        global $template, $pwg_loaded_plugins, $conf;

        $template->assign(array(
                               'loaded_plugins' => $GLOBALS['pwg_loaded_plugins'],
                               'meta_ref_enabled' => $conf['meta_ref']
                               ));
        if (array_key_exists('bootstrap_darkroom_core_js_in_header', $conf)) {
            $template->assign('bootstrap_darkroom_core_js_in_header', $conf['bootstrap_darkroom_core_js_in_header']);
        } else {
            $template->assign('bootstrap_darkroom_core_js_in_header', false);
        }

        if (isset($pwg_loaded_plugins['language_switch'])) {
            add_event_handler('loc_end_search', 'language_controler_flags', 95 );
            add_event_handler('loc_end_identification', 'language_controler_flags', 95 );
            add_event_handler('loc_end_tags', 'language_controler_flags', 95 );
            add_event_handler('loc_begin_about', 'language_controler_flags', 95 );
            add_event_handler('loc_end_register', 'language_controler_flags', 95 );
            add_event_handler('loc_end_password', 'language_controler_flags', 95 );
        }

        if (isset($pwg_loaded_plugins['exif_view'])) {
            load_language('lang.exif', PHPWG_PLUGINS_PATH.'exif_view/');
        }
    }

    public function exifReplacements($exif) {
        global $conf;

        if (array_key_exists('bootstrap_darkroom_ps_exif_replacements', $conf)) {
            foreach ($conf['bootstrap_darkroom_ps_exif_replacements'] as $tag => $replacement) {
               if (is_array($exif) && array_key_exists($tag, $exif)) {
                   $exif[$tag] = str_replace($replacement[0], $replacement[1], $exif[$tag]);
               }
            }
        }
        return $exif;
    }

    // register additional template files
    public function registerPictureTemplates() {
        global $template;

        $template->set_filenames(array('picture_nav'=>'picture_nav.tpl'));
        $template->parse_picture_buttons();
        $template->parse_index_buttons();
        $template->assign_var_from_handle('PICTURE_NAV', 'picture_nav');
    }

    public function stripBreadcrumbs() {
        global $page, $template;

        $l_sep = $template->get_template_vars('LEVEL_SEPARATOR');
        $title = $template->get_template_vars('TITLE');
        $section_title = $template->get_template_vars('SECTION_TITLE');
        if (empty($title)) {
            $title = $section_title;
        }
        if (!empty($title)) {
            $splt = strpos($title, "[");
            if ($splt) {
                $title_links = substr($title, 0, $splt);
                $title = $title_links;
            }

            $title = str_replace('<a href', '<a class="nav-breadcrumb-item" href', $title);
            $title = str_replace($l_sep, '', $title);
            if ($page['section'] == 'recent_cats' or $page['section'] == 'favorites') {
                $title = preg_replace('/<\/a>([a-zA-Z0-9]+)/', '</a><a class="nav-breadcrumb-item" href="' . make_index_url(array('section' => $page['section'])) . '">${1}', $title) . '</a>';
            }
            if ($template->get_template_vars('bd_simple_nav')) {
                // Visitors lose the Home crumb: on a share link it is a dead end.
                $home = preg_quote($template->get_template_vars('U_HOME'), '/');
                $title = preg_replace('/^<a class="nav-breadcrumb-item" href="' . $home . '">[^<]*<\/a>/', '', $title);
            }
            if (empty($section_title)) {
                $template->assign('TITLE', $title);
            } else {
                $template->assign('SECTION_TITLE', $title);
            }
        }
    }

    // The compact "< Album" back link: the parent album's link and the current album's name, read
    // from the breadcrumb once plugins have finished rewriting its URLs.
    public function assignBackLink() {
        global $template;

        if (!$template->get_template_vars('bd_simple_nav')) {
            return;
        }
        $title = $template->get_template_vars('SECTION_TITLE');
        if (empty($title)) {
            $title = $template->get_template_vars('TITLE');
        }
        preg_match_all('/<a class="nav-breadcrumb-item" href="([^"]*)"[^>]*>(.*?)<\/a>/s', (string)$title, $crumbs, PREG_SET_ORDER);
        $count = count($crumbs);
        $template->assign(array(
            'bd_crumb_parent_url' => $count > 1 ? $crumbs[$count - 2][1] : null,
            'bd_crumb_last_url' => $count > 0 ? $crumbs[$count - 1][1] : null,
            'bd_crumb_last_name' => $count > 0 ? $crumbs[$count - 1][2] : null,
        ));
    }

    public function getAllThumbnailsInCategory()
    {
        global $template, $conf, $user, $page;

        if (!$page['items'] || ($page['section'] == 'categories' && !isset($page['category']) && !isset($page['chronology_field']) && !isset($page['flat']))) {
          return;
        }

        if (count($page['items']) > 1000)
        {
          $this->config->slick_enabled = false; 
          $this->config->photoswipe = false; 

          return;
        }

        // select all pictures for this category
        $query = '
            SELECT 
              id,
              file,
              representative_ext,
              name,
              comment,
              width,
              height,
              date_creation,
              path,
              rotation
            FROM '.IMAGES_TABLE.'
            WHERE id IN ('.implode(',', $page['items']).')
            ORDER BY FIELD(id, '.implode(',', $page['items']).')
            ;';

        $result = pwg_query($query);

        $pictures = array();
        while ($row = pwg_db_fetch_assoc($result))
        {
            $pictures[] = $row;
        }

        $tpl_thumbnails_var = array();

        $theme_config = $template->get_template_vars('theme_config');

        foreach ($pictures as $row)
        {
            $url = duplicate_picture_url(
                array(
                    'image_id' => $row['id'],
                    'image_file' => $row['file'],
                   ),
                array('start')
            );

            $name = render_element_name($row);
            $desc = render_element_description($row, 'main_page_element_description');

            $tpl_var = array_merge($row, array(
                'NAME' => $name,
                'TN_ALT' => htmlspecialchars(strip_tags($name)),
                'URL' => $url,
                'DESCRIPTION' => htmlspecialchars(strip_tags($desc)),
                'src_image' => new \SrcImage($row),
                'SIZE' => $row['width'].'x'.$row['height'],
                'PATH' => $row['path'],
                'DATE_CREATED' => $row['date_creation'],
                'file_ext' => strtolower(get_extension($row['file'])),
                'path_ext' => strtolower(get_extension($row['path'])),
            ));

            $tpl_thumbnails_var[] = $tpl_var;
        }

        $template->assign('thumbnails', $tpl_thumbnails_var);

        $template->assign(array(
            'derivative_params_square' => trigger_change('get_index_derivative_params', \ImageStdParams::get_by_type( IMG_SQUARE ) ),
            'derivative_params_medium' => trigger_change('get_index_derivative_params', \ImageStdParams::get_by_type( IMG_MEDIUM ) ),
            'derivative_params_large' => trigger_change('get_index_derivative_params', \ImageStdParams::get_by_type( IMG_LARGE ) ),
            'derivative_params_xxlarge' => trigger_change('get_index_derivative_params', \ImageStdParams::get_by_type( IMG_XXLARGE ) ),
        ));

        unset($tpl_thumbnails_var, $pictures);
    }

}

?>
