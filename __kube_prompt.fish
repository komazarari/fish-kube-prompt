# Inspired from:
# https://github.com/jonmosco/kube-ps1
# https://github.com/Ladicle/fish-kubectl-prompt

set -U cmd_test (which /usr/bin/test || which /bin/test)
set -U stat_opts (man stat | grep BSD && echo -n "-f %m" || echo -n "-c %Y")

function __kube_ps_update_cache
  function __kube_ps_cache_context
    set -l ctx (kubectl config current-context 2>/dev/null)
    if $cmd_test $status -eq 0
      set -g __kube_ps_context "$ctx"
    else
      set -g __kube_ps_context "n/a"
    end
  end

  function __kube_ps_cache_namespace
    set -l ns (kubectl config view --minify -o 'jsonpath={..namespace}' 2>/dev/null)
    if $cmd_test -n "$ns"
      set -g __kube_ps_namespace "$ns"
    else
      set -g __kube_ps_namespace "default"
    end
  end

  set -l kubeconfig "$KUBECONFIG"
  if $cmd_test -z "$kubeconfig"
    set kubeconfig "$HOME/.kube/config"
  end

  if $cmd_test "$kubeconfig" != "$__kube_ps_kubeconfig"
    __kube_ps_cache_context
    __kube_ps_cache_namespace
    set -g __kube_ps_kubeconfig "$kubeconfig"
    set -g __kube_ps_timestamp (date +%s)
    return
  end

  for conf in (string split ':' "$kubeconfig")
    if $cmd_test -r "$conf"
      if $cmd_test -z "$__kube_ps_timestamp"; or $cmd_test (stat $stat_opts "$conf") -gt "$__kube_ps_timestamp"
#      if $cmd_test -z "$__kube_ps_timestamp"; or $cmd_test (stat -c '%Y' "$conf") -gt "$__kube_ps_timestamp"
        __kube_ps_cache_context
        __kube_ps_cache_namespace
        set -g __kube_ps_kubeconfig "$kubeconfig"
        set -g __kube_ps_timestamp (date +%s)
        return
      end
    end
  end
end

function __kube_prompt
  if $cmd_test -z "$__kube_ps_enabled"; or $cmd_test $__kube_ps_enabled -ne 1
    return
  end

  __kube_ps_update_cache
  echo -n -s " (⎈ $__kube_ps_context|$__kube_ps_namespace)"
end
