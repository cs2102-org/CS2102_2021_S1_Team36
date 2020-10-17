import { Component, OnInit } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';

@Component({
  selector: 'app-caretaker-bids',
  templateUrl: './caretaker-bids.component.html',
  styleUrls: ['./caretaker-bids.component.css']
})
export class CaretakerBidsComponent implements OnInit {
  filterForm = new FormGroup({
    search: new FormControl(''),
    date: new FormControl(''),
    petType: new FormControl('')
  });

  constructor() { }

  ngOnInit(): void {
  }
  
  onSubmit() {
    console.log('SENT');
  }
}
