import { Component, OnInit } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';
import { PcsadminService } from 'src/app/services/pcsadmin/pcsadmin.service';

@Component({
  selector: 'app-form-new-pet-type',
  templateUrl: './form-new-pet-type.component.html',
  styleUrls: ['./form-new-pet-type.component.css']
})
export class FormNewPetTypeComponent implements OnInit {
 typeForm = new FormGroup({
    species: new FormControl('', Validators.required)
  });

  constructor(private dialogRef: MatDialogRef<FormNewPetTypeComponent>, private pcsAdminService: PcsadminService) { }

  ngOnInit(): void {
  }
  
  onSubmitType(details) {
    this.pcsAdminService.postNewPetType(details).subscribe(msg => {
      this.dialogRef.close(true);
    })
  }
}
