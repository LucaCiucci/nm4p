
#import "../../common-typst/defs.typ": *

#show: common_styles

#appendix(label: "cubic-interpolation-with-derivatives")[
    Cubic interpolation with derivatives
][
    In this short appendix, I describe how to implement cubic interpolation given two points $y_i$ and their derivatives $y'_i$.

    We want a cubic in the form:
    $
    cases(
        y = a_0 + a_1 x + a_2 x^2 + a_3 x^3,
        y' = a_1 + 2 a_2 x + 3 a_3 x^2
    )
    $
    We get the following system:
    $
    underbrace(mat(
        1, 0, 0, 0;
        1, 1, 1, 1;
        0, 1, 0, 0;
        0, 1, 2, 3;
    ), E) vec(a_0, a_1, a_2, a_3) = vec(y_0, y_1, y'_0, y'_1)
    $
    We can solve this system by inverting the matrix:
    $
    vec(a_0, a_1, a_2, a_3) = E^(-1) vec(y_0, y_1, y'_0, y'_1)
    $
    The inverse of the matrix is (see #code_ref("/mod_1/appendixes/cubic-interpolation.typ")):
    $
    E^(-1) = mat(
        1, 0, 0, 0;
        0, 0, 1, 0;
        -3, 3, -2, -1;
        2, -2, 1, 1;
    )
    $
    The corresponding code can be found in #code_ref("/common/src/interpolation.rs", line: "fn interpolating_cubic")

    #let c = {
        import "@preview/cetz:0.1.2": canvas, draw, plot
        canvas(length: 1cm, {
            import draw: *
            line((-0.5, 0), (7, 0), mark: (end: ">"))
            line((0, -0.5), (0, 4), mark: (end: ">"))
            let p1 = (1, 1)
            let p2 = (6, 2)
            let d1 = 1.0
            let d2 = -1.5
            circle(p1, radius: 0.1, fill: black)
            circle(p2, radius: 0.1, fill: black)
            line(
                (p1.at(0) - 0.4, p1.at(1) - 0.4 * d1),
                (p1.at(0) + 0.4, p1.at(1) + 0.4 * d1),
                stroke: red + 2pt,
            )
            line(
                (p2.at(0) - 0.4, p2.at(1) - 0.4 * d2),
                (p2.at(0) + 0.4, p2.at(1) + 0.4 * d2),
                stroke: red + 2pt,
            )
            // note: this is not the cubic we are looking for,
            // but a graphically acceptable curve, just for the sake
            // of representation
            let d = 2.0
            draw.bezier(
                p1,
                p2,
                (p1.at(0) + d, p1.at(1) + d * d1),
                (p2.at(0) - d, p2.at(1) - d * d2)
            )
            content((p1.at(0), p1.at(1) - 0.5), $(x_0, y_0, y'_0)$)
            content((p2.at(0) - 0.75, p2.at(1) - 0.5), $(x_1, y_1, y'_0)$)
            // TODO formula di traslazione delle polinomiali
        })
    }
    #figure(
        c,
        caption: [
            Example of a cubic interpolating two points with fixed derivatives.
        ]
    ) <cubic-interpolation-example>

    //#{
    //    import "@preview/cetz:0.1.2": canvas, draw, plot
    //    let c = canvas(length: 1cm, {
    //        import draw: *
    //        line((0, 0), (1, 1))
    //        plot.plot(
    //            size: (8, 6),
    //            {
    //                //draw.set-style(stroke: red);
    //                let d = plot.add(
    //                    //hypograph: true,
    //                    style: (stroke: red + 2pt, mark: (stroke: blue)),
    //                    domain: (0, 3),
    //                    //mark: () => { 42 },
    //                    mark: "triangle",
    //                    x => x / 2,
    //                    samples: 10,
    //                );
    //                d
    //                //line((0, 0), (1, 10))
    //                plot.add-anchor("an", (1, 1.25))
    //            },
    //            //x-label: "ciao",
    //            x-label: $integral_0^1 y d x$,
    //            //x-grid: true,
    //            //y-grid: true,
    //            name: "plot"
    //        )
    //        //draw.anchor("an", (1, 10))
    //        line((0, 0), "plot.an")
    //    })
    //    c;
    //    let i = image.decode(read("/mod_1/img/plots/autocorr_fft-full.svg"), format: "svg");
    //}
]