# Custom skin (fork)

`custom.scss` builds `css/custom/bootstrap.css` and `bootstrap.min.css`, the Bootstrap base for the
**Custom** color theme. `css/custom/skin.css` is hand-written and loads on top of it. Both built
files are committed, so deploying is a `git pull` on the server.

`yarn build:custom` needs node-sass 4, which does not install on current Node. Dart Sass builds the
same file. From the theme root, with Bootstrap 4.3.1's SCSS in `<tools>/node_modules/bootstrap`:

```sh
npm install --prefix <tools> bootstrap@4.3.1 sass@1.77 postcss postcss-cli autoprefixer clean-css-cli
<tools>/node_modules/.bin/sass --load-path=<tools> --load-path=. --no-source-map --style=expanded --quiet \
    scss/custom/custom.scss css/custom/bootstrap.css
<tools>/node_modules/.bin/postcss css/custom/bootstrap.css --no-map --use autoprefixer --replace
<tools>/node_modules/.bin/cleancss -O1 -o css/custom/bootstrap.min.css css/custom/bootstrap.css
```

After deploying, purge the compiled templates (Administration > Tools > Maintenance) so the combined
CSS is rebuilt.
