use clap::builder::{styling::AnsiColor, Styles};
use mexprp::{Answer, Calculation, Expression, Func, MathError};



pub const CLI_STYLES: Styles = Styles::styled()
    .header(AnsiColor::Green.on_default().bold())
    .usage(AnsiColor::Green.on_default().bold())
    .literal(AnsiColor::BrightCyan.on_default().bold())
    .placeholder(AnsiColor::Cyan.on_default());


/// Parses a mathematical expression that depends on `x` and returns a function that can be evaluated
pub fn parse_expression_x_to_1(expr: &str) -> anyhow::Result<Box<dyn FnMut(f64) -> anyhow::Result<f64>>> {
    let mut expr = Expression::parse_ctx(expr, make_math_context())?;
    Ok(Box::new(move |x: f64| -> anyhow::Result<f64>{
        expr.ctx.set_var("x", x);
        let v: Answer<f64> = expr.eval()?;
        let v = match v {
            Answer::Single(v) => v,
            Answer::Multiple(values) => anyhow::bail!("Expected a single value, got multiple: {values:?}"),
        };
        //if v < 0.0 {
        //    anyhow::bail!("Expected a positive value, got: {v}");
        //}
        Ok(v)
    }))
}

/// Configures the expression context with some custom functions
fn make_math_context() -> mexprp::Context<f64> {
    let mut context = mexprp::Context::<f64>::new();
    context.set_func("exp", RealFn(f64::exp));
    context
}

struct RealFn(fn (f64) -> f64);

impl Func<f64> for RealFn {
    fn eval(&self, args: &[mexprp::Term<f64>], ctx: &mexprp::Context<f64>) -> Calculation<f64> {
        if args.len() != 1 {
            return Err(MathError::IncorrectArguments);
        }

        let a = args[0].eval_ctx(ctx)?;

        a.unop(|a| Ok(Answer::Single(self.0(*a))))
    }
}