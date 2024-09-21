import matplotlib.pyplot as plt
import sys
import yaml
import click

@click.command()
@click.argument('input_file', type=click.Path(exists=True), required=False)
@click.option('--out', type=click.Path(), help='Output file')
@click.option('--show', is_flag=True, help='Show the plot')
@click.option('--style', help='Plot style', default='.')
def main(input_file: str | None, show: bool, out: str | None, style: str):
    if input_file is None:
        documents = yaml.safe_load_all(sys.stdin)
    else:
        with open(input_file, 'r') as f:
            documents = yaml.safe_load_all(f)
    meta = next(documents)
    data = next(documents)

    xx = [entry['x'] for entry in data]

    plt.plot(xx, style, label='data')
    plt.xlabel('MC time [step]')
    plt.ylabel('value')
    plt.title(f'Metropolis for {meta['f']}\nacceptance = {data[-1]['acc']/len(data):.2f}')
    plt.grid(True)

    curr_ylim = plt.gca().get_ylim()
    max_ylim = max(abs(curr_ylim[0]), abs(curr_ylim[1]))
    plt.ylim(-max_ylim, max_ylim)

    # place the meta information in the plot
    text = ""
    for key, value in meta.items():
        text += f"{key}: {value}\n"
    text = text.strip()
    plt.text(
        0.0, 0.0, text,
        horizontalalignment='left',
        verticalalignment='bottom',
        transform=plt.gca().transAxes,
        bbox=dict(facecolor='white', alpha=0.95),
    )

    if out:
        plt.savefig(out)

    if show:
        plt.show()

if __name__ == '__main__':
    main()