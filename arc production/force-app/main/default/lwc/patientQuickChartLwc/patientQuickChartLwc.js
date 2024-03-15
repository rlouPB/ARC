/* eslint-disable vars-on-top */
import { LightningElement, api, track } from "lwc";
import { loadScript, loadStyle } from "lightning/platformResourceLoader";
import chartjs from "@salesforce/resourceUrl/chartJs";
import getRecords from "@salesforce/apex/PatientChartController.getChartMetricData";
import getAccountId from "@salesforce/apex/PatientChartController.getAccountId";
import getAccountNameFromId from "@salesforce/apex/PatientChartController.getAccountNameFromId";
import getFieldLabels from "@salesforce/apex/PatientChartController.getFieldLabels";
const BACKGROUND_COLORS = ["rgba(255, 99, 132, 0.2)", "rgba(54, 162, 235, 0.2)", "rgba(255, 206, 86, 0.2)", "rgba(75, 192, 192, 0.2)", "rgba(153, 102, 255, 0.2)", "rgba(255, 159, 64, 0.2)", "rgba(0, 0, 0, 0.2)"];
const BORDER_COLORS = ["rgba(255, 99, 132, 1)", "rgba(54, 162, 235, 1)", "rgba(255, 206, 86, 1)", "rgba(75, 192, 192, 1)", "rgba(153, 102, 255, 1)", "rgba(255, 159, 64, 1)", "rgba(0, 0, 0, 1)"];

export default class PatientQuickChartLwc extends LightningElement {
	@api asOfDate;
	@api chartTitle;
	@api dateField;
	@api fieldName1;
	@api fieldName2;
	@api fieldName3;
	@api fieldName4;
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
	@track datasetLabels = [];
	@track error;
	@track fieldCount = 0;
	@track fieldLabels = [];
	@track labels = [];
	@track values = [];
	config = {
		type: "bar",
		data: {
			datasets: [
				{
					data: this.values,
					backgroundColor: this.backgroundColors[1],
					borderColor: this.borderColors[1],
					borderWidth: 1
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
		},
		plugins: {
			subtitle: {
				display: true,
				text: this.accountName
			}
		}
	};

	@api
	async load() {
		this.loading = true;

		this.accountId = await getAccountId({
			recordId: this.recordId
		});

		this.accountName = await getAccountNameFromId({
			recordId: this.accountId
		});

		this.fieldLabels = await getFieldLabels({
			objectName: this.objectName,
			fieldName1: this.fieldName1,
			fieldName2: this.fieldName2,
			fieldName3: this.fieldName3,
			fieldName4: this.fieldName4
		});

		this.chartData = await getRecords({
			objectName: this.objectName,
			fieldName1: this.fieldName1,
			fieldName2: this.fieldName2,
			fieldName3: this.fieldName3,
			fieldName4: this.fieldName4,
			patientField: this.patientField,
			asOfDate: this.asOfDate,
			dateField: this.dateField,
			patientId: this.accountId
		});

		this.chartData.forEach((element) => {
			if (element[this.fieldName1]) {
				if (!this.values[0]) {
					this.labels.push(this.fieldLabels[0]);
					this.values.push(element[this.fieldName1]);
					this.fieldCount++;
				}
			}
			if (element[this.fieldName2]) {
				if (!this.values[1]) {
					this.labels.push(this.fieldLabels[1]);
					this.values.push(element[this.fieldName2]);
					this.fieldCount++;
				}
			}
			if (element[this.fieldName3]) {
				if (!this.values[2]) {
					this.labels.push(this.fieldLabels[2]);
					this.values.push(element[this.fieldName3]);
					this.fieldCount++;
				}
			}
			if (element[this.fieldName4]) {
				if (!this.values[3]) {
					this.labels.push(this.fieldLabels[3]);
					this.values.push(element[this.fieldName4]);
					this.fieldCount++;
				}
			}
		});

		this.loading = false;
	}

	async renderedCallback() {
		await this.load();

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
				console.log("renderedCallback error: " + error);
				this.error = error;
			});
	}
}