

#include <iostream>
#include <functional>
#include <random>
#include <cassert>
#include <cmath>
#include <chrono>

#include <ranges>

#include <TF1.h>
#include <TH1.h>
#include <TApplication.h>
#include <TCanvas.h>
#include <TRootCanvas.h>
#include <TGraph.h>
#include <TAxis.h>
#include <TMultiGraph.h>
#include <TLegend.h>

#include <TColor.h>

#include <TBrowser.h>

#include <array>

//#include <gnuplotpp/gnuplotpp.hpp>


// confligge in span !!!

#include <nm4pLib/ext/pocketfft_hdronly.h>

#include <nm4pLib/metropolis.hpp>
#include <nm4pLib/utils/itrange.hpp>
#include <nm4pLib/utils/ranges.hpp>
#include <nm4pLib/utils/stat.hpp>
#include <nm4pLib/HistoData.hpp>

using lc::experimental::itrange;
using lc::experimental::RangeOfValueType;
using lc::experimental::sqr;
using lc::experimental::mean;
using lc::experimental::var;
using lc::experimental::autocorrVec;
using lc::experimental::autocorrFFT;

using namespace std::chrono_literals;
using namespace std::string_literals;

using namespace nm4pLib;

void show_points(const std::vector<double>& data, size_t maxN = std::numeric_limits<size_t>::max());
void show_histo(const HistoData& histo);

TCanvas* show_corr(const std::vector<double>& corr, size_t maxN = std::numeric_limits<size_t>::max());
TCanvas* show_corr2(const std::vector<double>& corr_exact, const std::vector<double>& corr_fft, size_t maxN = std::numeric_limits<size_t>::max());

void closes_app(TCanvas* canvas)
{
	TRootCanvas* rc = (TRootCanvas*)canvas->GetCanvasImp();
	rc->Connect("CloseWindow()", "TApplication", gApplication, "Terminate()");
}

void corr_comparison(bool zero_padding)
{
	std::default_random_engine engine;

	const double sigma = 1.0;
	const double mu = 5;
	auto gaussian = [sigma, mu](double x) { return std::exp(-sqr(x - mu) / (2 * sqr(sigma))); };

	constexpr size_t stride = 1;
	constexpr size_t N = 10000;
	const double delta = 0.1;
	const double startingValue = mu;

	auto result = metropolis_1d(gaussian, startingValue, delta, N, stride);
	auto& data = result.xx;
	std::cout << "acceptance: " << result.acceptance << std::endl;
	std::cout << data.size() << std::endl;
	std::cout << "media: " << mean(data) << std::endl;
	std::cout << "var: " << var(data) << std::endl;
	std::cout << "std: " << sqrt(var(data)) << std::endl;


	// plotting
	{
		std::vector<double> corr = autocorrVec(data, 10000);
		std::vector<double> corr2 = autocorrFFT(data, mean(data), zero_padding ? data.size() : (size_t)0);

		auto canvas = show_corr2(corr, corr2);

		std::string fileName = "corrconf"s + (zero_padding ? "-zero-padding"s : ""s) + ".root"s;
		canvas->SaveAs(fileName.c_str());

		canvas->WaitPrimitive();
	}
}

void corr_overview()
{
	std::default_random_engine engine;

	const double sigma = 1.0;
	const double mu = 5;
	auto gaussian = [sigma, mu](double x) { return std::exp(-sqr(x - mu) / (2 * sqr(sigma))); };

	constexpr size_t stride = 1;
	constexpr size_t N = 1e7;
	const double delta = 0.1; // 3.124;
	const double startingValue = mu;

	auto result = metropolis_1d(gaussian, startingValue, delta, N, stride);
	auto& data = result.xx;
	std::cout << "acceptance: " << result.acceptance << std::endl;
	std::cout << data.size() << std::endl;
	std::cout << "media: " << mean(data) << std::endl;
	std::cout << "var: " << var(data) << std::endl;
	std::cout << "std: " << sqrt(var(data)) << std::endl;


	// plotting
	{
		std::vector<double> corr = autocorrFFT(data, mean(data), data.size());

		for (auto maxK : std::vector{ 5000, 10000 })
		{
			auto canvas = show_corr(corr, maxK);

			std::string fileName = "autocorr-N-1e7-"s + std::to_string(maxK) + ".root"s;
			canvas->SaveAs(fileName.c_str());

			canvas->WaitPrimitive();
		}
	}
}


int main(int argc, char** argv)
{
	std::cout << "Hello There" << std::endl;

	TApplication app("app", &argc, argv);

	if (false)
	{
		corr_comparison(false);
		corr_comparison(true);
	}

	if (true)
	{
		corr_overview();
	}

	//app.Run();
	return 0;

	std::default_random_engine engine;

	const double sigma = 0.25;
	const double mu = 5;

	auto gaussian = [sigma, mu](double x) { return std::exp(-sqr(x - mu) / (2 * sqr(sigma))); };
	auto step = [sigma, mu](double x) {
		if (x < mu - sigma || x > mu + sigma)
			return 0;
		if (x < mu)
			return 1;
		return 2;
	};

	auto distribution = gaussian;
	
	

	const size_t stride = 1;
	constexpr size_t N = 150000*0+10000000*0 + 1e7*0+ 10000;
	const double delta = 0.1;
	const double startingValue = mu*0;

	auto result = metropolis_1d(distribution, startingValue, delta, N, stride);
	auto& data = result.xx;
	std::cout << "acceptance: " << result.acceptance << std::endl;
	std::cout << data.size() << std::endl;
	std::cout << "media: "<< mean(data) << std::endl;
	std::cout << "var: "<< var(data) << std::endl;
	std::cout << "std: "<< sqrt(var(data)) << std::endl;

	show_points(data, 15000);

	// compute the histogram
	auto histo = HistoData::from(data, mu - sigma * 5, mu + sigma * 5, 100);

	show_histo(histo);

	if (1) {
		//std::vector<double> corr = autocorrVec2(data, 10000);
		std::vector<double> corr2 = autocorrFFT(data, mean(data), data.size());
		//corr.resize(10000);
		//corr2.resize(10000);
		//auto c = show_corr(corr2, 20000);
		//c->SaveAs("autocorr-N-1e7-20000.root");
		//c = show_corr(corr2, 5000);
		//c->SaveAs("autocorr-N-1e7-5000.root");
		//show_corr2(corr, corr2);
		auto e = show_corr(corr2, 10000);
		e->SaveAs("mtp.root");
	}

	new TBrowser;


	app.Run();

	// ((TRootCanvas*)c->GetCanvasImp())->Connect("CloseWindow()", "TApplication", gApplication, "Terminate()");

	return 0;
}

void show_points(const std::vector<double>& data, size_t maxN)
{
	// TODO "campione"
	auto canvas = new TCanvas("points_canvas", "Pointset", 200, 10, 700, 500);
	auto graph = new TGraph;
	for (size_t i = 0; i < data.size() && i < maxN; ++i)
		graph->AddPoint(i, data[i]);

	graph->SetTitle("Pointset");

	graph->SetMarkerStyle(EMarkerStyle::kPlus);
	graph->SetMarkerStyle(EMarkerStyle::kFullCircle);
	graph->SetMarkerStyle(EMarkerStyle::kDot);
	//g->SetMarkerSize(5);
	graph->SetMarkerColorAlpha(kBlack, 0.25);

	graph->Draw("AP");

	canvas->SetGrid();
}

void show_histo(const HistoData& histo)
{
	auto canvas = new TCanvas("chisto", "Some Histo");

	auto histogram = new TH1F("histo", "istogramma", histo.bins.size(), histo.minX, histo.maxX);

	//cout << h->GetSize() << endl;
	for (size_t i = 0; i < histo.bins.size(); ++i)
		histogram->SetAt(histo.bins[i], i);

	TColor color;
	histogram->SetFillColorAlpha(kViolet, 0.125);
	histogram->SetLineColor(kViolet);
	histogram->Draw();
}

TCanvas* show_corr(const std::vector<double>& corr, size_t maxN)
{
	auto canvas = new TCanvas("autocorr", "Autocorrelazione", 200, 10, 700, 500);
	auto graph = new TGraph;
	for (size_t i = 0; i < corr.size() && i < maxN; ++i)
		graph->AddPoint(i, corr[i]);


	graph->SetTitle("Autocorrelation;k;\\[c_k\\]");

	//g->SetMarkerStyle(EMarkerStyle::kPlus);
	graph->SetMarkerStyle(EMarkerStyle::kFullCircle);
	//graph->SetMarkerStyle(EMarkerStyle::kDot);
	graph->SetMarkerSize(0.25);
	graph->SetMarkerColor(kBlack);

	graph->Draw("APL");

	canvas->SetGrid();

	return canvas;
}
TCanvas* show_corr2(const std::vector<double>& corr_exact, const std::vector<double>& corr_fft, size_t maxN)
{
	auto canvas = new TCanvas("corrconf", "Confronto Correlazione", 200, 10, 700, 500);
	
	auto graph = new TGraph;
	for (size_t i = 0; i < corr_exact.size() && i < maxN; ++i)
		graph->AddPoint(i, corr_exact[i]);

	//g->SetMarkerStyle(EMarkerStyle::kPlus);
	//graph->SetMarkerStyle(EMarkerStyle::kFullCircle);
	graph->SetMarkerStyle(EMarkerStyle::kDot);
	graph->SetMarkerSize(0.5);
	graph->SetMarkerColor(kRed);
	graph->SetLineColor(kRed);
	graph->SetTitle("\\[c_k\\]");

	auto graph2 = new TGraph;
	for (size_t i = 0; i < corr_fft.size() && i < maxN; ++i)
		graph2->AddPoint(i, corr_fft[i]);

	//g->SetMarkerStyle(EMarkerStyle::kPlus);
	//graph2->SetMarkerStyle(EMarkerStyle::kFullCircle);
	graph2->SetMarkerStyle(EMarkerStyle::kDot);
	graph2->SetMarkerSize(0.5);
	graph2->SetMarkerColor(kBlack);
	graph2->SetTitle("\\[c_k\\] (FFT)");

	auto mg = new TMultiGraph();
	mg->Add(graph, "PL");
	mg->Add(graph2, "PL");

	//mg->Draw("A");
	
	//gPad->Modified();
	mg->SetTitle("Correlation Coparison;k;\\[c_k\\]");
	mg->GetYaxis()->SetLimits(-0.5, 1);
	graph->GetYaxis()->SetLimits(-0.5, 1);
	graph2->GetYaxis()->SetLimits(-0.5, 1);
	mg->SetMinimum(-0.5);
	mg->SetMaximum(1.5);
	mg->Draw("A");
	gPad->Modified();
	gPad->Update();
	//canvas->DrawFrame(0, -0.5, 10000, 1);

	auto legend = new TLegend(0.1, 0.8, 0.3, 0.9);
	legend->AddEntry(graph);
	legend->AddEntry(graph2);
	legend->Draw();
	//canvas->Draw();
	//auto l = canvas->BuildLegend();

	canvas->SetGrid();

	return canvas;
}