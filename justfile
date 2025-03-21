# REMOVE-ME-START ------------------------------------------------------------
# Automatic setup for the template itself
# You should only have to run this once at the very beginning, then
# you can delete this part of the justfile!
_setup package_name:
    @echo "Setting up your project for the first time!"
    @echo "You have provided package name {{ package_name }}"
    sed -i '' -e "s/{% package_name %}/test_package_name/" justfile pyproject.toml
    mv package {{ package_name }}
# REMOVE-ME-END --------------------------------------------------------------

# Simply prints the current version to stdout
print-version:
    @echo "Current version is:" `uvx --with hatch hatch version`

# Automatic version bumping script.
# Convenient way to manage your versions by hand but without constantly
# having to manually change the _version.py file.
[confirm]
apply-version version: print-version
    uvx --with hatch hatch version {{ version }}
    sed -n "s/__version__ = '\(.*\)'/\\1/p" {% package_name %}/_version.py > .version.tmp
    git add {% package_name %}/_version.py
    uv lock --upgrade-package {% package_name %}
    git add uv.lock
    git commit -m "Bump version to $(cat .version.tmp)"
    if [ {{ version }} != "dev" ]; then git tag -a "v$(cat .version.tmp)" -m "Bump version to $(cat .version.tmp)"; fi
    rm .version.tmp

# Serves documentation built with sphinx
# Requires the doc extra dependency in the pyproject.toml file
# Watches for changes to the source code in the {% package_name %} directory
serve-docs:
    uv run --extra doc sphinx-autobuild -b html docs/source docs/build --open-browser --watch {% package_name %}

# Serves an instance of jupyterlab via pm2 using sensible defaults.
# Obviously, change this to your heart's content!
serve-jupyter:
    pm2 start 'uv run --with=ipython,jupyterlab,matplotlib,seaborn,h5netcdf,netcdf4,scikit-learn,scipy,xarray,"nbconvert==5.6.1" jupyter lab --notebook-dir="~" --no-browser' --name {% package_name %}
