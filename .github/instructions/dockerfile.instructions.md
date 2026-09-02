---
applyTo: "**/Dockerfile,**/Dockerfile.*,**/*.dockerfile"
---

# Dockerfile instructions

This file is the single source of truth for all Dockerfile standards in this project.

## HEREDOC for multiline commands

**Always use HEREDOC syntax for multiline RUN commands.** Do not use backslash line continuations with `&&` chains.

### Correct (HEREDOC)

```dockerfile
RUN <<EOF
apt-get update
apt-get install -y package1 package2
rm -rf /var/lib/apt/lists/*
EOF
```

### Incorrect (backslash continuations)

```dockerfile
# Do NOT use this style
RUN apt-get update \
 && apt-get install -y package1 package2 \
 && rm -rf /var/lib/apt/lists/*
```

## HEREDOC benefits

- Improved readability with clear script structure
- Easier to maintain and modify individual lines
- No need to manage trailing backslashes
- Syntax highlighting works better in editors

## Shell selection

Use `bash` when you need bash-specific features:

```dockerfile
RUN <<EOF bash
set -euo pipefail
if [[ -f /tmp/config ]]; then
 source /tmp/config
fi
EOF
```

## Single commands

Single commands do not require HEREDOC:

```dockerfile
COPY .terraform-version /tmp/.terraform-version
WORKDIR /app
ENV PATH="/usr/local/bin:$PATH"
```
