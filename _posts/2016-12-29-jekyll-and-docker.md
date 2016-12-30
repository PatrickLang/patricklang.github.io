---
layout: post
title: "Jekyll made easy with Docker"
date: 2016-12-29
---

I have been working with Markdown for my work on [Windows Containers](http://aka.ms/windowscontainers), and wanted to try using it for other purposes too like this blog. It's easy to learn and has a great balance of content to markup. One problem, however, is that it requires a lot of steps to set it up. Let's see how Docker can come to the rescue.

## What's needed
- A Linux machine with the Docker Engine already set up
- Your GitHub pages repo
- [jekyll/jekyll](https://hub.docker.com/r/jekyll/jekyll/)


## So let's get started

Pull your existing GitHub Pages repo:

```bash
git clone https://github.com/PatrickLang/patricklang.github.io.git
```

Run it with the default command:
`docker run --rm --label=jekyll --volume=$(pwd):/srv/jekyll -it -p 4000:4000 jekyll/jekyll`

And it will start up running in the foreground.

```bash
Configuration file: /srv/jekyll/_config.yml
            Source: /srv/jekyll
       Destination: /srv/jekyll/_site
 Incremental build: disabled. Enable with --incremental
      Generating...
                    done in 0.404 seconds.
 Auto-regeneration: enabled for '/srv/jekyll'
Configuration file: /srv/jekyll/_config.yml
    Server address: http://0.0.0.0:4000/
  Server running... press ctrl-c to stop.
```

Now, you can access it on the Docker host at http://<ip>:4000/

For more details, check out the [jekyll/docker wiki](https://github.com/jekyll/docker/wiki)

## Rendering Drafts on-the-fly

The whole reason I set this up was so that I could take advantage of Jekyll's draft support to render (but not publish) some work-in-progress pages. All I needed to do was give a custom command when I started the container:

```bash
 docker run --label=jekyll --volume=$(pwd):/srv/jekyll -it -d -p 4000:4000 jekyll/jekyll jekyll serve --drafts
```

By running it in the background with `-d`, I can continue to `git pull` to get updated drafts that I'm writing on another machine and render them instantly.