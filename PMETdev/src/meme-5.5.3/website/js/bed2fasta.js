var sequences = null;

function register_component(id, element, controler) {
  "use strict";
  if (id == "sequences") {
    sequences = controler;
  }
}

function check() {
  "use strict";
  var alphs = null;
  if (sequences != null) {
    if (!sequences.check(alphs)) return false;
  }
  if (!check_job_details()) return false;
  return true;
}

function options_changed() {
  return false;
}

function options_reset(evt) {
}

function fix_reset() {
}

function on_form_submit(evt) {
  if (!check()) {
    evt.preventDefault();
  }
}

function on_form_reset(evt) {
  window.setTimeout(function(evt) {
    fix_reset();
  }, 50);
}

function on_pageshow() {
  sequences._source_update();
}

function on_load() {
  // add listener to the form to check the fields before submit
  $("bed2fasta_form").addEventListener("submit", on_form_submit, false);
  $("bed2fasta_form").addEventListener("reset", on_form_reset, false);
  window.addEventListener('pageshow', on_pageshow, false);
}

// add a load
(function() {
  "use strict";
  window.addEventListener("load", function load(evt) {
    "use strict";
    window.removeEventListener("load", load, false);
    on_load();
  }, false);
})();

