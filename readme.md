# Envar spaces

Spaces for [envar tool](https://github.com/varlogerr/toolbox.envar2)

## Installation

```sh
git clone git@github.com:varlogerr/envar.spaces.git \
  ~/Projects/envar.spaces

ln -s ~/Projects/envar.spaces/spaces "${ENVAR_SPACE_PATH}"

# and don't forget to add configurations in
# ~/Projects/envar.spaces/secrets
```

**Alternative**:

```sh
# `~/.envar` directory must be empty before git clone.
# after clone command `init.d` and other files and
# directories can be added 
git clone git@github.com:varlogerr/envar.spaces.git \
  ~/.envar

# and don't forget to add configurations in
# ~/Projects/envar.spaces/secrets
```
