/* eslint-disable vars-on-top */
import { LightningElement, api, track } from "lwc";
import { loadScript, loadStyle } from "lightning/platformResourceLoader";
import chartjs from "@salesforce/resourceUrl/chartJs";
import getAccountId from "@salesforce/apex/PatientChartController.getAccountId";
import getAccountNameFromId from "@salesforce/apex/PatientChartController.getAccountNameFromId";
import getFieldLabel from "@salesforce/apex/PatientChartController.getFieldLabel";
import getRecords from "@salesforce/apex/PatientChartController.getChartTimeData";

const BACKGROUND_COLORS = ["rgba(255, 99, 132, 0.2)", "rgba(54, 162, 235, 0.2)", "rgba(255, 206, 86, 0.2)", "rgba(75, 192, 192, 0.2)", "rgba(153, 102, 255, 0.2)", "rgba(255, 159, 64, 0.2)", "rgba(0, 0, 0, 0.2)"];
const BORDER_COLORS = ["rgba(255, 99, 132, 1)", "rgba(54, 162, 235, 1)", "rgba(255, 206, 86, 1)", "rgba(75, 192, 192, 1)", "rgba(153, 102, 255, 1)", "rgba(255, 159, 64, 1)", "rgba(0, 0, 0, 1)"];

export default class PatientQuickChartTimeLwc extends LightningElement {
	@api chartTitle;
	@api dateField;
	@api fieldName;
	@api iconName;
	@api objectName;
	@api patientField;
	@api recordId;
	@api showPatientName;
	@track accountId;
	@track accountName;
	@track backgroundColors = BACKGROUND_COLORS;
	@track borderColors = BORDER_COLORS;
	@track chartData;
	@track chartjsInitialized = false;
	@track config;
	@track error;
	@track executing = false;
	@track fieldLabel;
	@track labels = [];
	@track showSpinner = false;
	@track values = [];

	@api
	async init() {
		// Force reinitialization of values because renderedCallback executes twice, creating duplicates
		this.chartData = [];
		this.chartjsInitialized = false;
		this.config = "";
		this.error = "";
		this.labels = [];
		this.values = [];
	}

	async initializeChart() {
		this.config = {
			type: "bar",
			data: {
				datasets: [
					{
						data: this.values,
						backgroundColor: this.backgroundColors[5],
						borderColor: this.borderColors[5],
						borderWidth: 1,
						label: this.fieldLabel
					}
				],
				labels: this.labels
			},
			options: {
				responsive: true,
				legend: {
					display: false
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

	@api
	async load() {
		await this.init();
		this.loading = true;

		this.accountId = await getAccountId({
			recordId: this.recordId,
			accountField: this.patientField
		});

		this.accountName = await getAccountNameFromId({
			accountId: this.accountId
		});

		this.fieldLabel = await getFieldLabel({
			objectName: this.objectName,
			fieldName: this.fieldName
		});

		this.chartData = await getRecords({
			objectName: this.objectName,
			fieldName: this.fieldName,
			patientField: this.patientField,
			dateField: this.dateField,
			patientId: this.accountId
		});

		this.chartData.forEach((element) => {
			if (element[this.fieldName] && element[this.dateField]) {
				this.labels.push(this.formatDateString(element[this.dateField]));
				this.values.push(element[this.fieldName]);
			}
		});

		// chartData is delivered from the controller by descending date.Values and labels
		// are reversed, in order to render the data from left to right where the most
		// recent entry is the rightmost entry.
		this.values.reverse();
		this.labels.reverse();

		await this.initializeChart();
		this.loading = false;
	}

	formatDateString(dateString) {
		// Added by Sols, reference ARC-2443 110822
		let [year, month, day] = dateString.split("-");

		month = month.startsWith("0") ? month.substr(1) : month;
		day = day.startsWith("0") ? day.substr(1) : day;

		const result = [month, day, year].join("/");
		return result;
	}

	async renderedCallback() {
		// variable executing prevents multiple executions causing duplicated this.values
		// renderedCallback is called twice
		if (!this.executing) {
			this.executing = true;
			this.showSpinner = true;
			await this.load();
			await this.renderDataChart();
			this.showSpinner = false;
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
				this.chart = new window.Chart(ctx, this.config);
			})
			.catch((error) => {
				console.log("patientQuickChartTimeLwc error: " + error);
				this.error = error;
			});
		// this.executing = false;
	}
}