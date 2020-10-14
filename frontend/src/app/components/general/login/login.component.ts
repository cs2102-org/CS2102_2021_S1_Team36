import { Component, OnInit } from '@angular/core';
import { FormGroup, FormControl } from '@angular/forms';
import { Validators } from '@angular/forms';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent implements OnInit {

  loginForm = new FormGroup({
    email: new FormControl('', [Validators.required, Validators.email]),
    password: new FormControl('', Validators.required),
  });

  constructor() { }

  ngOnInit(): void {
  }

  onSubmit() {
    console.log("SENT");
  }

}
// <div class="buttons" >
//   <button type="button"[routerLink] = "['/signup']" > Signup < /button>
//     < button type = "submit"[disabled] = "!loginForm.valid" > Submit < /button>
//       < /div>