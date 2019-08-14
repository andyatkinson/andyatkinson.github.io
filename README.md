## Hello!

This is the source for my website, blog, and portfolio at [andyatkinson.com](https://andyatkinson.com) built with Jekyll and hosted on GitHub Pages.


#### Writing Style Tips

 * Use `h4` for headings
 * Add tags to the post
 * In Vim `:set wrap`/`:set nowrap` to enable/disable soft wrap
 * In Vim `leader-s` enables spell check mode, check spelling, add words with `zg` [Vim Spell Checking](https://thoughtbot.com/blog/vim-spell-checking) by Thoughtbot
 * Use initial caps in post titles
 * Use `<mark/>` to highlight a section
 * Use footnotes when appropriate
 * For blockquotes, add a `<cite/>`
 * On OS X, preview with MacDown [MacDown](https://macdown.uranusjr.com/) The open source Markdown editor for macOS.
 * For section headings, use caps
 * For product and company names, mind the CamelCase
 * For dates on posts, use a date and not a time

#### Theme Bugs and Issues

~~The `include` for the social link icons does not work on Heroku but worked locally. The `icons` folder is nested one layer deeper and it may just be that the relative filepath is not working.~~
This was worked around for now by inlining the contents of the `include`.

Multi-word tags had a whitespace character after the hyphen. Removed that so URLs worked.

`site.baseurl` did not have a leading slash in `_layouts/post.html` and did elsewhere, so this was breaking links. For now I manually inserted the leading slash in that file.

#### More Resources

 * [Setting up Namecheap DNS with GitHub Pages](https://www.namecheap.com/support/knowledgebase/article.aspx/9645/2208/how-do-i-link-my-domain-to-github-pages)
 * [Setting up GitHub Pages Custom Domains](https://github.blog/2018-05-01-github-pages-custom-domains-https/)
 * [Setting up a Newsletter with Mailchimp](https://mailchimp.com/help/share-your-blog-posts-with-mailchimp/)
 * [Jekyll SEO plugin for GitHub Pages](https://help.github.com/en/articles/search-engine-optimization-for-github-pages)

#### Development

    bundle exec jekyll serve --incremental

I occasionally `rm -rf _site` to remove the generated site completely. Changing `config.yml` requires restarting the development server.
