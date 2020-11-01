import { Component, OnInit, ViewChild } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { CalendarOptions, FullCalendarComponent } from '@fullcalendar/angular';
import dayGridPlugin from '@fullcalendar/daygrid';
import { CaretakerService } from 'src/app/services/caretaker/caretaker.service';

@Component({
  selector: 'app-caretaker-summary-page',
  templateUrl: './caretaker-summary-page.component.html',
  styleUrls: ['./caretaker-summary-page.component.css']
})
export class CaretakerSummaryPageComponent implements OnInit {

  @ViewChild('calendar') calendarComponent: FullCalendarComponent;

  calendarOptions: CalendarOptions = {
    initialView: 'dayGridMonth',
    events: [],
    selectable: true,
    unselectAuto: false,
    select: this.selectLeaveDate.bind(this)
  };

  leaveForm = new FormGroup({
    start_date: new FormControl('', Validators.required),
    end_date: new FormControl('', Validators.required)
  });


  constructor(private caretakerService: CaretakerService) { }

  ngOnInit(): void {
  }

  ngAfterViewInit(): void {
    this.calendarComponent.getApi().render();
  }

  getLeave() {
    
  }

  getBids() {

  }

  selectLeaveDate(selectionInfo) {
    const startDate = selectionInfo.start;
    const endDate = selectionInfo.end;
    startDate.setDate(startDate.getDate() + 1);
    this.leaveForm.controls['start_date'].setValue(startDate.toISOString().slice(0,10));
    this.leaveForm.controls['end_date'].setValue(endDate.toISOString().slice(0,10));
  }

  onSubmit() {
    this.caretakerService.postNewLeave(this.leaveForm.value).subscribe(msg => {
      if (msg) {
        console.log("success");
      }
    });
  }
}
