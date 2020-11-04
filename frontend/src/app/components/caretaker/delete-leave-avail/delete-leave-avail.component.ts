import { Component, Inject, OnInit } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { CaretakerService } from 'src/app/services/caretaker/caretaker.service';
import { BidDialogComponent } from '../../general/bid-dialog/bid-dialog.component';

@Component({
  selector: 'app-delete-leave-avail',
  templateUrl: './delete-leave-avail.component.html',
  styleUrls: ['./delete-leave-avail.component.css']
})
export class DeleteLeaveAvailComponent implements OnInit {
  date;
  type;
  msg='';

  constructor(private dialogRef: MatDialogRef<BidDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: any, private caretakerService: CaretakerService) { }

  ngOnInit(): void {
    const startDate = this.data.dataKey;
    startDate.setDate(startDate.getDate() + 1);
    this.date = startDate.toISOString().slice(0,10);
    this.type = this.data.type === "Leave" ? "leave" : "availability";
  }

  delete() {
    if (this.type === "leave") {
      this.caretakerService.deleteLeave(this.date).subscribe(msg => {
        this.dialogRef.close(true);
      });
    } else {
      this.caretakerService.deleteAvail(this.date).subscribe(msg => {
        this.dialogRef.close(true);
      }, (err) => {
        this.msg = "You have a job on this date!";
      }
      );
    }
  }
}
