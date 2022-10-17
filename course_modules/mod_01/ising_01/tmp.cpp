

#include "TF1.h"
#include "TApplication.h"
#include "TCanvas.h"
#include "TRootCanvas.h"

#include <TH2.h>
#include <Math/TRandomEngine.h>

#include <TGraph.h>
#include <TGraphErrors.h>
#include <TMultiGraph.h>

#include <random>

std::default_random_engine engine;
std::normal_distribution<double> d(0, 1);

int main(int argc, char** argv)
{
	TApplication app("app", &argc, argv);

	if (0)
	{
		TCanvas* canvas = new TCanvas("c", "Something", 0, 0, 800, 600);

		TF1* f1 = new TF1("f1", "sin(x)", -5, 5);
		f1->SetLineColor(kBlue + 1);
		f1->SetTitle("My graph;x; sin(x)");
		f1->Draw();
		canvas->Modified(); canvas->Update();
		TRootCanvas* rc = (TRootCanvas*)canvas->GetCanvasImp();
		rc->Connect("CloseWindow()", "TApplication", gApplication, "Terminate()");
	}


	if (0) {
		auto c1 = new TCanvas("c1", "c1", 600, 600);
		c1->Divide(1, 2);
		auto hcol23 = new TH2F("hcol23", "Option COLZ example ", 40, -4, 4, 40, -20, 20);
		auto hcol24 = new TH2F("hcol24", "Option COLZ1 example ", 40, -4, 4, 40, -20, 20);
		float px  =0, py = 0;
		for (Int_t i = 0; i < 25000; i++) {
			//gRandom->Rannor(px, py);
			px = d(engine);
			py = d(engine);
			
			hcol23->Fill(px, 5 * py);
			hcol24->Fill(px, 5 * py);
		}
		hcol23->Fill(0., 0., -200.);
		hcol24->Fill(0., 0., -200.);
		c1->cd(1); hcol23->Draw("COLZ");
		c1->cd(2); hcol24->Draw("COLZ1");
	}

	if (0)
	{
		auto c = new TCanvas("c", "A Zoomed Graph", 200, 10, 700, 500);
		c->DrawFrame(0, 1, 0.5, 8);
		//c->DrawFrame(0, 0, 1, 1);

		int n = 10;
		double x[10] = { -.22,.05,.25,.35,.5,.61,.7,.85,.89,.95 };
		double y[10] = { 1,2.9,5.6,7.4,9,9.6,8.7,6.3,4.5,1 };

		auto gr = new TGraph(n, x, y);
		gr->SetMarkerColor(4);
		gr->SetMarkerStyle(20);
		gr->Draw("LP");
	}

	if (1)
	{
		{
			// Create the points:
			const int n = 10;
			double x[n] = { -.22,.05,.25,.35,.5,.61,.7,.85,.89,.95 };
			double y[n] = { 1,2.9,5.6,7.4,9,9.6,8.7,6.3,4.5,1 };
			double x2[n] = { -.12,.15,.35,.45,.6,.71,.8,.95,.99,1.05 };
			double y2[n] = { 1,2.9,5.6,7.4,9,9.6,8.7,6.3,4.5,1 };

			// Create the width of errors in x and y direction:
			double ex[n] = { .05,.1,.07,.07,.04,.05,.06,.07,.08,.05 };
			double ey[n] = { .8,.7,.6,.5,.4,.4,.5,.6,.7,.8 };

			// Create two graphs:
			TGraph* gr1 = new TGraph(n, x2, y2);
			TGraphErrors* gr2 = new TGraphErrors(n, x, y, ex, ey);

			// Create a TMultiGraph and draw it:
			TMultiGraph* mg = new TMultiGraph();
			mg->Add(gr1);
			mg->Add(gr2);
			mg->Draw("ALP");
		}
	}

	{
		TCanvas* c03 = new TCanvas("c03", "c03", 700, 400);
		//gStyle->SetOptStat(0);
		TH2F* htext3 = new TH2F("htext3", "Several 2D histograms drawn with option TEXT", 10, -4, 4, 10, -20, 20);
		TH2F* htext4 = new TH2F("htext4", "htext4", 10, -4, 4, 10, -20, 20);
		TH2F* htext5 = new TH2F("htext5", "htext5", 10, -4, 4, 10, -20, 20);
		Float_t px, py;
		for (Int_t i = 0; i < 25000; i++) {
			//gRandom->Rannor(px, py);
			//gRandom->Rannor(px, py);
			px = d(engine);
			py = d(engine);
			htext3->Fill(4 * px, 20 * py, 0.1);
			htext4->Fill(4 * px, 20 * py, 0.5);
			htext5->Fill(4 * px, 20 * py, 1.0);
		}
		//gStyle->SetPaintTextFormat("4.1f m");
		htext4->SetMarkerSize(1.8);
		htext5->SetMarkerSize(1.8);
		htext5->SetMarkerColor(kRed);
		htext3->Draw("COL");
		htext4->SetBarOffset(0.2);
		htext4->Draw("TEXT SAME");
		htext5->SetBarOffset(-0.2);
		htext5->Draw("TEXT SAME");
		//return c03;
	}

	app.Run();

	return 0;
}