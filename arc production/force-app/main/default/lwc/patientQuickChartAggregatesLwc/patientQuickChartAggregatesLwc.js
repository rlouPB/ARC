/* eslint-disable vars-on-top */
import { LightningElement, api, track } from "lwc";
import { loadScript, loadStyle } from "lightning/platformResourceLoader";
import chartjs from "@salesforce/resourceUrl/chartJs";
import getAccountId from "@salesforce/apex/PatientChartController.getAccountId";
import getAccountNameFromId from "@salesforce/apex/PatientChartController.getAccountNameFromId";
import getAggregateRecords from "@salesforce/apex/PatientChartController.getAggregateChartData";
import getPicklistValues from "@salesforce/apex/PatientChartController.getPicklistValues";
import getFieldLabel from "@salesforce/apex/PatientChartController.getFieldLabel";
import getNumMonths from "@salesforce/apex/PatientChartController.getNumberMonthsFromDateRange";
const BACKGROUND_COLORS = ["rgba(255, 99, 132, 0.2)", "rgba(54, 162, 235, 0.2)", "rgba(255, 206, 86, 0.2)", "rgba(75, 192, 192, 0.2)", "rgba(153, 102, 255, 0.2)", "rgba(255, 159, 64, 0.2)", "rgba(0, 0, 0, 0.2)"];
const BORDER_COLORS = ["rgba(255, 99, 132, 1)", "rgba(54, 162, 235, 1)", "rgba(255, 206, 86, 1)", "rgba(75, 192, 192, 1)", "rgba(153, 102, 255, 1)", "rgba(255, 159, 64, 1)", "rgba(0, 0, 0, 1)"];

export default class PatientQuickChartAggregatesLwc extends LightningElement {
	// @api vars prefixed with 'configChart' are designated during setup & config on Lightning page
	@api configField;
	@api configObject;
	@api configTitle;
	@api configDateField;
	@api configDateRange;
	@api configIconName;
	@api configIsDateTime;
	@api configAcctIdField;
	@api configShowName;
	@api recordId;
	@track accountId;
	@track accountName;
	@track chartConfig;
	@track chartData = [];
	@track chartjsInitialized = false;
	@track chartLabels = [];
	@track chartNumMonths;

	// vars prefixed with 'dataset' represent the data used by chartJS to render the chart
	@track datasetBarColors = [];
	@track datasetBorderColors = [];
	@track datasetFieldLabel; // Mouseover(s) and chart Legend (if applicable)
	@track datasetLabels = [];
	@track datasetSize = 0;
	@track datasetValues = [];
	@track error;
	@track executing = false; // Used to discourage recursive calls
	@track loading = false;

	async initializeChart() {
		let listOfObjects = [];

		for (let i = 0; i < this.datasetLabels.length; i++) {
			let singleObj = {};
			singleObj["label"] = this.datasetLabels[i];
			singleObj["data"] = this.datasetValues[i];
			singleObj["backgroundColor"] = this.datasetBarColors[i];
			singleObj["borderColor"] = this.datasetBorderColors[i];
			singleObj["borderWidth"] = 1;
			listOfObjects.push(singleObj);
		}

		this.chartConfig = {
			type: "bar",
			data: {
				labels: this.chartLabels,
				datasets: listOfObjects
			},
			options: {
				responsive: true,
				legend: {
					position: "bottom"
				},
				animation: {
					animateScale: true,
					animateRotate: true
				},
				scales: {
					yAxes: [
						{
							display: true,
							ticks: {
								beginAtZero: true
							}
						}
					]
				}
			}
		};
	}

	async populateVariables() {
		let aggregateVals = [];
		let picklistVals = [];
		this.accountId = await getAccountId({
			recordId: this.recordId
		});

		this.accountName = await getAccountNameFromId({
			recordId: this.accountId
		});

		this.datasetFieldLabel = await getFieldLabel({
			objectName: this.configObject,
			fieldName: this.configField
		});

		this.chartNumMonths = await getNumMonths({
			dateRange: this.configDateRange
		});

		picklistVals = await getPicklistValues({
			objectName: this.configObject,
			fieldName: this.configField
		});

		this.datasetLabels = JSON.parse(JSON.stringify(picklistVals));

		this.chartData = await getAggregateRecords({
			objectName: this.configObject,
			fieldName: this.configField,
			patientField: this.configAcctIdField,
			dateRange: this.configDateRange,
			dateField: this.configDateField,
			isDateTime: this.configIsDateTime,
			accountId: this.accountId
		});

		this.chartData.forEach((element) => {
			this.chartLabels.push(element.formattedMonthYear);
			aggregateVals.push(element.count);
		});

		return aggregateVals;
	}

	@api
	async load() {
		this.loading = true;
		let aggregateVals = await this.populateVariables();
		await this.createDatasets(aggregateVals);
		await this.removeDuplicateChartLabels();
		await this.initializeChart();
		this.loading = false;
	}

	async renderedCallback() {
		if (!this.executing) {
			this.executing = true;
			await this.load();
			this.renderDataChart();
		}
	}

	async createDatasets(values) {
		let beginIdx = 0;
		let valuesRemaining = values.length;
		this.datasetSize = valuesRemaining / this.datasetLabels.length;

		// Dataset values
		do {
			this.datasetValues.push(values.slice(beginIdx, beginIdx + this.datasetSize));
			valuesRemaining = valuesRemaining - this.datasetSize;
			beginIdx += this.datasetSize;
		} while (valuesRemaining > 0);

		// Dataset bar colors
		for (let i = 0; i < this.datasetSize; i++) {
			this.datasetBarColors.push(BACKGROUND_COLORS[i]);
		}

		// Dataset bar border colors
		for (let j = 0; j < this.datasetSize; j++) {
			this.datasetBorderColors.push(BORDER_COLORS[j]);
		}
	}

	renderDataChart() {
		if (this.chartjsInitialized) {
			return;
		}
		this.chartjsInitialized = true;

		Promise.all([loadScript(this, chartjs + "/Chart.min.js"), loadStyle(this, chartjs + "/Chart.min.css")])
			.then(() => {
				window.Chart.platform.disableCSSInjection = true;
				const canvas = document.createElement("canvas");
				this.template.querySelector("div.chart").appendChild(canvas);
				const ctx = canvas.getContext("2d");
				this.chart = new window.Chart(ctx, this.chartConfig);
			})
			.catch((error) => {
				console.log("renderedCallback error: " + error);
				this.error = error;
			});
	}

	async removeDuplicateChartLabels() {
		let labelSet = [...new Set(this.chartLabels)];
		this.chartLabels = [];
		this.chartLabels.push(...labelSet);
	}
}