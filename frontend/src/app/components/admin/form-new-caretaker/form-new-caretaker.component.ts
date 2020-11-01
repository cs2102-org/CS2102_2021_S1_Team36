import { Component, OnInit } from '@angular/core';
import { MatDialogRef } from '@angular/material/dialog';

@Component({
  selector: 'app-form-new-caretaker',
  templateUrl: './form-new-caretaker.component.html',
  styleUrls: ['./form-new-caretaker.component.css']
})
export class FormNewCaretakerComponent implements OnInit {

  constructor(private dialogRef: MatDialogRef<FormNewCaretakerComponent>) { }

  ngOnInit(): void {
  }

}
