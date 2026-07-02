# Edge Cases — Agent Core Standalone (#115)

1. **GitHub token missing** — push требует GITHUB_TOKEN или PAT
2. **CI runner timeout** — tests run < 30s, no timeout risk
3. **npm registry down** — CI fails, retry on rerun
4. **Branch protection** — master branch not protected (open source)
