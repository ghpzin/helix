open languages.toml
| get grammar
| where {|e| $e.source.git =~ "https://github.com" }
| par-each --threads 30 {|e|
  let source_split = $e.source.git 
    | str replace 'https://github.com/' ''
    | split column '/' owner repo 
    | get 0;
  let prefetch_cmd = $"nix-prefetch-github ($source_split.owner) ($source_split.repo) --rev ($e.source.rev)";
  let prefetch_out = $"(cached-nix-shell -p nix-prefetch-github --command $'($prefetch_cmd)')"
    | from json;

  { 
    $e.name:{
      url: $e.source.git,
      owner: $source_split.owner,
      repo: $source_split.repo,
      rev: $e.source.rev,
      hash: $prefetch_out.hash
    }
  }
}
| reduce {|it, acc| $acc | merge $it}
| to json
| save grammar.json -f
