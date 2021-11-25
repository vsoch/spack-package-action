---
layout: page
title: Papers
css: ["about.css", "animate.css", "morphext.css"]
js: ["morphext.min.js", "about.js"]
permalink: /results/
---

<div class="thi-columns">
  <ul class="tag-post">
  {% for result in site.results %}
    <a class="post-title" href="{{ site.baseurl }}{{ result.url }}">
      <li>
        {{ result.title }} 
      </li>
    </a>
  {% endfor %}
  </ul>
</div>
