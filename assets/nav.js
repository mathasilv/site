/* ============================================================
   assets/nav.js — injeta o menu COMMAND (sidebar) compartilhado.
   Uso: no HTML coloque <div id="site-nav"></div> e chame
   <script src="assets/nav.js" defer></script> (ou carregue e
   chame Site.renderNav()). Ajusta o link "atual" automaticamente.
   ============================================================ */
(function () {
  "use strict";

  var LINKS = [
    { href: "index.html",    label: "HOME" },
    { href: "projects.html", label: "POSTS" },
    { href: "gallery.html",  label: "PHOTOS" },
    { href: "mailto:msouza449@gmail.com", label: "CONTACT" }
  ];

  function currentName() {
    var p = location.pathname.split("/").pop() || "index.html";
    return p;
  }

  function panelOutset(inner) {
    return '' +
      '<div class="panel-outset" style="margin-bottom:15px;">' +
      '  <h3 style="text-align:center;font-size:14px;margin-bottom:5px;">COMMAND</h3>' +
      inner +
      '</div>';
  }

  function navBtn(link) {
    var cur = currentName();
    var active = (link.href === cur) ? ' style="outline:1px dotted #000;"' : '';
    return '<a href="' + link.href + '" class="nav-btn"' + active + '>' + link.label + '</a>';
  }

  function renderNav(target) {
    if (!target) return;
    target.innerHTML = panelOutset(LINKS.map(navBtn).join(""));
  }

  function auto() {
    var t = document.getElementById("site-nav");
    if (t) renderNav(t);
  }

  var Site = window.Site || {};
  Site.renderNav = renderNav;
  Site.NAV_LINKS = LINKS;
  window.Site = Site;

  if (document.readyState !== "loading") auto();
  else document.addEventListener("DOMContentLoaded", auto);
})();
