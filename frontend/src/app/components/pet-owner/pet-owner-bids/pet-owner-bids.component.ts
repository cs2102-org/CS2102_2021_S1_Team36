import { Component, OnInit } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';

@Component({
  selector: 'app-pet-owner-bids',
  templateUrl: './pet-owner-bids.component.html',
  styleUrls: ['./pet-owner-bids.component.css']
})
export class PetOwnerBidsComponent implements OnInit {
  filterForm = new FormGroup({
    search: new FormControl(''),
    date: new FormControl(''),
    petType: new FormControl('')
  });

  constructor() { }

  ngOnInit(): void {
  }

  onSubmit(searchParam) {
    console.log('SENT');
    console.log(searchParam);
  }
}
