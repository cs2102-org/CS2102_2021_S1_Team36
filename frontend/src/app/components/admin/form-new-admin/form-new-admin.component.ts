import { Component, OnInit } from '@angular/core';
import { MatDialogRef } from '@angular/material/dialog';

@Component({
  selector: 'app-form-new-admin',
  templateUrl: './form-new-admin.component.html',
  styleUrls: ['./form-new-admin.component.css']
})
export class FormNewAdminComponent implements OnInit {

  constructor(private dialogRef: MatDialogRef<FormNewAdminComponent>) { }

  ngOnInit(): void {
  }

}
