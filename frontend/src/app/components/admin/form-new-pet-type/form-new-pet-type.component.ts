import { Component, OnInit } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';

@Component({
  selector: 'app-form-new-pet-type',
  templateUrl: './form-new-pet-type.component.html',
  styleUrls: ['./form-new-pet-type.component.css']
})
export class FormNewPetTypeComponent implements OnInit {
 typeForm = new FormGroup({
    pet_type: new FormControl('', Validators.required)
  });

  constructor(private dialogRef: MatDialogRef<FormNewPetTypeComponent>) { }

  ngOnInit(): void {
  }
  
  onSubmitType(){}
}
