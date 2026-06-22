---
layout: page
title: archive
permalink: /archive/
description: Collection of all posts.
---

<div class="search-container">
  <md-outlined-text-field id="search-input" label="Search posts..." autocomplete="off" type="search" style="--md-outlined-text-field-leading-space: 0; --md-outlined-text-field-trailing-space: 0;"></md-outlined-text-field>
</div>

<ul class="post-list" id="archive-list">
    {% for post in site.posts %}
    <li data-title="{{ post.title | downcase }}" data-tags="{{ post.tags | join: ' ' | downcase }}" data-description="{{ post.description | downcase }}">
        <a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
        <p class="post-meta">{{ post.date | date: '%B %-d, %Y' }}</p>
    </li>
    {% endfor %}
</ul>

<p class="search-no-results" id="no-results" style="display:none;">No posts found.</p>

<script type="module">import 'https://esm.run/@material/web/textfield/outlined-text-field.js';</script>
<script src="https://cdn.jsdelivr.net/npm/fuse.js/dist/fuse.min.js"></script>
<script>
(function () {
  const input = document.getElementById('search-input');
  const items = Array.from(document.querySelectorAll('#archive-list li'));
  const noResults = document.getElementById('no-results');
  let fuse;

  function initFuse() {
    if (fuse) return;
    const posts = items.map(function (li) {
      return {
        el: li,
        title: li.dataset.title,
        tags: li.dataset.tags,
        description: li.dataset.description
      };
    });
    fuse = new Fuse(posts, {
      keys: ['title', 'tags', 'description'],
      threshold: 0.4,
      ignoreLocation: true
    });
  }

  input.addEventListener('input', function () {
    const query = this.value.trim();
    if (!query) {
      items.forEach(function (li) { li.style.display = ''; });
      noResults.style.display = 'none';
      return;
    }
    initFuse();
    const matches = new Set(fuse.search(query).map(function (r) { return r.item.el; }));
    let visible = 0;
    items.forEach(function (li) {
      if (matches.has(li)) { li.style.display = ''; visible++; }
      else { li.style.display = 'none'; }
    });
    noResults.style.display = visible === 0 ? '' : 'none';
  });
})();
</script>
