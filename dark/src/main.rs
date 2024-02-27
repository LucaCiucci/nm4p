use nannou::prelude::*;

fn main() {
    nannou::app(model).update(update).run();
}

struct Lattice {
    nx: usize,
    ny: usize,
    sites: Vec<(f64, f64, f64, f64, f64)>,
    field: Box<dyn Fn(usize, usize) -> f64>,
}

impl Lattice {
    fn new(nx: usize, ny: usize, field: impl Fn(usize, usize) -> f64 + 'static) -> Self {
        let mut sites = Vec::new();
        for _ in 0..nx {
            for _ in 0..ny {
                sites.push((0.0, 0.0, 0.0, 0.0, 0.0));
            }
        }
        Self { nx, ny, sites, field: Box::new(field) }
    }

    fn site(&self, i: usize, j: usize) -> (f64, f64, f64, f64, f64) {
        self.sites[i + j * self.nx]
    }

    fn site_mut(&mut self, i: usize, j: usize) -> &mut (f64, f64, f64, f64, f64) {
        &mut self.sites[i + j * self.nx]
    }

    fn position(&self, i: usize, j: usize) -> (f64, f64) {
        let (x, y, _, _, _) = self.site(i, j);
        let x = x + i as f64;
        let y = y + j as f64;
        (x, y)
    }
}

struct Model {
    _window: window::Id,
    lattice: Lattice,
}

fn model(app: &App) -> Model {
    let _window = app.new_window().view(view).build().unwrap();

    let mut lattice = Lattice::new(
        50,
        50,
        |x, y| {
            if (x, y) == (10, 10) {
                0.0
            } else {
                0.0
            }
        },
    );

    //lattice.site_mut(10, 10).4 = 10.0;

    Model {
        _window,
        lattice,
    }
}

fn step(lattice: &mut Lattice) {
    const DT: f64 = 0.001;

    const R: f64 = 0.5;

    //let r = -1.0/DT;
    //println!("r = {}", r);

    let s = 1.0;

    lattice.site_mut(10, 10).4 += s * DT;
    lattice.site_mut(10, 25).4 += s * DT;
    lattice.site_mut(25, 10).4 += s * DT;
    lattice.site_mut(40, 25).4 += s * DT;
    lattice.site_mut(40, 40).4 += s * DT;
    lattice.site_mut(10, 40).4 += s * DT;
    lattice.site_mut(40, 10).4 += s * DT;
    lattice.site_mut(25, 40).4 += s * DT;

    for i_x in 1..(lattice.nx - 1) {
        for i_y in 1..(lattice.ny - 1) {
            let mut fx = 0.0;
            let mut fy = 0.0;
            let (x, y, vx, vy, w) = lattice.site(i_x, i_y);
            let field = &lattice.field;
            fx += lattice.site(i_x + 1, i_y).0 - lattice.site(i_x + 1, i_y).4 - field(i_x + 1, i_y) - x + w + field(i_x, i_y);
            fx += lattice.site(i_x - 1, i_y).0 + lattice.site(i_x - 1, i_y).4 + field(i_x - 1, i_y) - x - w - field(i_x, i_y);
            fx += lattice.site(i_x, i_y + 1).0 - x;
            fx += lattice.site(i_x, i_y - 1).0 - x;
            fy += lattice.site(i_x, i_y + 1).1 - lattice.site(i_x, i_y + 1).4 - field(i_x, i_y + 1) - y + w + field(i_x, i_y);
            fy += lattice.site(i_x, i_y - 1).1 + lattice.site(i_x, i_y - 1).4 + field(i_x, i_y - 1) - y - w - field(i_x, i_y);
            fy += lattice.site(i_x + 1, i_y).1 - y;
            fy += lattice.site(i_x - 1, i_y).1 - y;
            *lattice.site_mut(i_x, i_y) = (
                //x + vx * DT + fx * DT * DT / 2.0,
                //y + vy * DT + fy * DT * DT / 2.0,
                x + vx * DT,
                y + vy * DT,
                vx + fx * DT,
                vy + fy * DT,
                w,
            )
        }
    }
    for i_x in 0..(lattice.nx - 1) {
        for i_y in 0..(lattice.ny - 1) {
            {
                let other = lattice.site(i_x + 1, i_y).4;
                let this = lattice.site(i_x, i_y).4;
                let diff = other - this;
                let flux = diff * R;
                lattice.site_mut(i_x, i_y).4 += flux * DT;
                lattice.site_mut(i_x + 1, i_y).4 -= flux * DT;
            }
            {
                let other = lattice.site(i_x, i_y + 1).4;
                let this = lattice.site(i_x, i_y).4;
                let diff = other - this;
                let flux = diff * R;
                lattice.site_mut(i_x, i_y).4 += flux * DT;
                lattice.site_mut(i_x, i_y + 1).4 -= flux * DT;
            }
        }
    }
    for p in lattice.sites.iter_mut() {
        let (_, _, vx, vy, w) = p;
        *w *= 0.99999;
        *vx *= 0.99999;
        *vy *= 0.99999;
    }
    // boundary conditions
    for i_x in 0..(lattice.nx) {
        *lattice.site_mut(i_x, 0) = (0.0, 0.0, 0.0, 0.0, 0.0);
        *lattice.site_mut(i_x, lattice.ny - 1) = (0.0, 0.0, 0.0, 0.0, 0.0);
    }
    for i_y in 0..(lattice.ny) {
        *lattice.site_mut(0, i_y) = (0.0, 0.0, 0.0, 0.0, 0.0);
        *lattice.site_mut(lattice.nx - 1, i_y) = (0.0, 0.0, 0.0, 0.0, 0.0);
    }
}

fn update(_app: &App, model: &mut Model, _update: Update) {
    //lattice.site_mut(10, 10).4 += 0.1 * DT;
    //model.lattice.site_mut(10, 10).4 = 1.0;

    for _ in 0..1000 {
        step(&mut model.lattice);
    }

    let avg_temperature = model.lattice.sites.iter().map(|(_, _, _, _, w)| w).sum::<f64>() / model.lattice.sites.len() as f64;
    println!("avg_temperature = {}", avg_temperature);
}

fn view(app: &App, model: &Model, frame: Frame) {
    let draw = app.draw();
    let win = app.window_rect();

    {
        draw.background().color(BLACK);
        //draw.ellipse().color(STEELBLUE);
        //draw.ellipse().radius(1.0).x(100.0).y(50.0);

        let r_x = win.w() / (model.lattice.nx - 1) as f32;
        let r_y = win.h() / (model.lattice.ny - 1) as f32;
        let map = |(x, y): (f64, f64)| (x as f32 * r_x - win.w() / 2.0, y as f32 * r_y - win.h() / 2.0);
        for i_x in 0..(model.lattice.nx - 1) {
            for i_y in 0..(model.lattice.ny - 1) {
                let (x, y) = map(model.lattice.position(i_x, i_y));
                let (x1, y1) = map(model.lattice.position(i_x + 1, i_y));
                let (x2, y2) = map(model.lattice.position(i_x, i_y + 1));
                draw.line().start(pt2(x, y)).end(pt2(x1, y1)).color(GRAY);
                draw.line().start(pt2(x, y)).end(pt2(x2, y2)).color(GRAY);
            }
        }
        let field = &model.lattice.field;
        for i_x in 0..model.lattice.nx {
            for i_y in 0..model.lattice.ny {
                let (x, y) = map(model.lattice.position(i_x, i_y));
                let r = model.lattice.site(i_x, i_y).4 as f32 * 8.0;
                let f = field(i_x, i_y) as f32 * 8.0;
                draw.ellipse().radius(r + f).x(x).y(y).color(RED);
                draw.ellipse().radius(f).x(x).y(y).color(CYAN);
            }
        }
    }

    draw.to_frame(app, &frame).unwrap();
}