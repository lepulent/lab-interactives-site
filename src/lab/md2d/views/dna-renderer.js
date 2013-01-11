/*global $ define: false, d3: false */

define(function (require) {

  return function DNARenderer(container, parentView, model) {
    var api,
        nm2px,
        nm2pxInv,

        init = function() {
          // Save shortcuts.
          nm2px = parentView.nm2px;
          nm2pxInv = parentView.nm2pxInv;
          // Redraw DNA on every DNA properties change.
          model.getDNAProperties().on("change", api.setup);
        },

        renderText = function(container, txt, fontSize, dy) {
          // Text shadow.
          container.append("text")
            .text(txt)
            .attr({
              "class": "shadow",
              "dy": dy
            })
            .style({
                "stroke-width": nm2px(0.01),
                "font-size": fontSize
            });

          // Final text.
          container.append("text")
            .text(txt)
            .attr({
              "class": "front",
              "dy": dy
            })
            .style("font-size", fontSize);
        };

    api = {
      setup: function () {
        var dna = model.getDNAProperties().get(),
            dnaGElement, fontSize;

        if (dna === undefined) {
          return;
        }

        container.selectAll("g.dna").remove();

        dnaGElement = container.append("g").attr({
          "class": "dna",
          // (0nm, 0nm) + small, constant offset in px.
          "transform": "translate(" + nm2px(dna.x) + "," + nm2pxInv(dna.y) + ")"
        });

        fontSize = nm2px(dna.height) + "px";

        // Basic sequence.
        // [ fontSize is a string already (with "px" suffix), so simple -fontSize will result in NaN. ]
        renderText(dnaGElement, dna.sequence, fontSize, "-" + fontSize);
        // Complementary sequence.
        renderText(dnaGElement, dna.complementarySequence, fontSize, 0);
      }
    };

    init();

    return api;
  };
});
