import { Component, OnInit } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { baseurl, getHttpOptionsWithAuth, httpOptions } from '../../../services/commons.service';
import { FormControl, FormGroup, FormBuilder, FormArray, Validators } from '@angular/forms';
import { AuthService } from 'src/app/services/auth/auth.service';
import { PetownerService } from 'src/app/services/petowner/petowner.service';
import { NONE_TYPE } from '@angular/compiler';
import { registerLocaleData } from '@angular/common';
import { CaretakerService } from 'src/app/services/caretaker/caretaker.service';

@Component({
  selector: 'app-caretaker-profile',
  templateUrl: './caretaker-profile.component.html',
  styleUrls: ['./caretaker-profile.component.css']
})
export class CaretakerProfileComponent implements OnInit {

  userData = {caretaker: NONE_TYPE, petowner: NONE_TYPE};
  flatData;
  isCaretaker = false;
  isPetOwner = false;
  isPcsAdmin = false;
  pets = [];
  petTypes;
  email;
  msg = '';

  petArray = new FormArray([]);
  petForm: FormGroup;

  takeCareArray = new FormArray([]);
  takeCareForm: FormGroup;
  prices;
  takeCareSpecies;
  is_fulltime: boolean = false;

  constructor(private http: HttpClient,
              private fb: FormBuilder,
              private authService: AuthService,
              private caretakerService: CaretakerService,
              private petOwnerService: PetownerService) {
    this.petForm = this.fb.group({
      name:'',
      petArrays: this.fb.array([]),
    });

    this.takeCareForm = this.fb.group({
      name:'',
      takeCareArrays: this.fb.array([]),
    })
  }

  profileForm = new FormGroup({
    name: new FormControl(''),
    password: new FormControl('', [Validators.required, Validators.minLength(4)]),
    description: new FormControl(''),
    case: new FormControl(''),
  });

  public getUser(): Observable<any> {
    return this.http.get(baseurl + '/api/auth/profile', getHttpOptionsWithAuth());
  }

  public updateUser(details): Observable<any> {
    return this.http.put(baseurl + '/api/auth/update', details, getHttpOptionsWithAuth());
  }

  getUserData() {
    this.getUser().subscribe((user) => {
      
      this.flatData = user.flat()[0];      
      if (user[0][0] != undefined) {this.userData['caretaker'] = user[0][0]; this.isCaretaker = true;}
      if (user[1][0] != undefined) {this.userData['petowner'] = user[1][0]; this.isPetOwner = true;}
      if (user[2][0] != undefined) {this.userData['pcsadmin'] = user[2][0]; this.isPcsAdmin = true;}
      console.log('isCaretaker:'+this.isCaretaker+', isPetOwner:'+this.isPetOwner+', isPcsAdmin');
      console.log(user);
      console.log("sada" + localStorage.getItem('is_fulltime'));
      if (localStorage.getItem('is_fulltime') == 'true') {
        this.is_fulltime=true;
      }
      this.getPrices();
      this.profileForm.patchValue({
        name: this.flatData.name,
        password: this.flatData.password,
        description: this.flatData.description,
      })});
  }

  getOwnerPets() {
    this.petOwnerService.getPetOwnerPets().subscribe((pets) => {
       this.pets = pets;
       this.petArray = new FormArray([]);
       console.log(pets);
       this.populatePetArray();
    });
  }

  ngOnInit(): void {
    this.getUserData();
    this.getOwnerPets();
    this.getListOfPetTypes();
  }

  populatePetArray() {
    for (const pet of this.pets) {
      console.log(pet);
      
      const group = this.fb.group({
      pet_name: {value: pet.pet_name, disabled: true},
      special_requirements: pet.special_requirements,
      description: pet.description,
      species: pet.species,
      })

      this.petArrays.push(group);
    }
  }


  get petArrays(): FormArray {
    return this.petForm.get("petArrays") as FormArray;
  }

  newPet(): FormGroup {
    return this.fb.group({
      pet_name: '',
      special_requirements: '',
      description: '',
      species: '',
    })
  }

  addPets() {
    this.msg = '';
    this.petArrays.push(this.newPet());
  }

  updatePet(i: number) {
    var updated = this.petArrays.at(i).value;
    var original = this.pets[i];
    console.log(updated);
    console.log(this.pets);
    if (original == undefined) {
      this.addPetHttp(updated);
      return;
    }
    updated.pet_name = this.pets[i].pet_name;
    this.updatePetHttp(updated);
  }

  removePet(i: number) {
    var removal = this.petArrays.at(i).value;
    removal.pet_name = this.pets[i].pet_name;
    this.petArrays.removeAt(i);
    this.removePetHttp(removal);
  }

  addPetHttp(details){
    this.http.post(baseurl + '/api/petowner/addpet', details, getHttpOptionsWithAuth()).subscribe(x => {
      console.log(x);
      if (!x) {
        alert("Incorrect Params");
      } else {
        this.msg = "Added pet successfully!";
      }
    });
  }

  updatePetHttp(details){
    this.http.put(baseurl + '/api/petowner/updatepet', details, getHttpOptionsWithAuth()).subscribe(x => {
      console.log(x);
      if (!x) {
        alert("Incorrect Params");
      } else {
        this.msg = "Updated Successfully!";
      }
    });
  }

  removePetHttp(details) {
    this.http.post(baseurl + '/api/petowner/deletepet', details, getHttpOptionsWithAuth()).subscribe(x => {
      console.log(x);
      this.msg = "Successfully Deleted!";
    });
  }

  onSubmit(profileParam): void {
    console.log('SENT');
    console.log(profileParam);
    this.updateUser(profileParam).subscribe(x => {
      if (!x) {
        alert("Please enter valid details");
      } else {
        this.msg = "Updated Successfully!";
      }
    });
  }

  onSubmitPetArray() {
    console.log(this.petForm.value);
  }


  ///////////////// CareTaker TakeCare Price///////////////////////

  populateTakeCareArray() {
    this.takeCareForm = this.fb.group({
      name:'',
      takeCareArrays: this.fb.array([]),
    });

    for (const takecare of this.prices) {
      const group = this.fb.group({
      species: takecare.species,
      daily_price: takecare.daily_price,
      base_price: takecare.base_price
      })

      this.takeCareArrays.push(group);
    }
    this.takeCareSpecies = this.prices.map((x) => x.species);
    console.log(this.takeCareSpecies);
  }

  getListOfPetTypes() {
    this.petOwnerService.getListOfPetTypes().subscribe(petTypes => {
      this.petTypes = petTypes.map(elem => elem.species);
      console.log(this.petTypes);
    });
  }

  getPrices() {
    this.caretakerService.getCareTakerPrice(this.flatData.email).subscribe((prices) => {
      this.prices = prices;
      this.populateTakeCareArray();
      console.log(prices);
    });
  }

  get takeCareArrays(): FormArray {
    return this.takeCareForm.get("takeCareArrays") as FormArray;
  }

  newTakeCare(): FormGroup {
    return this.fb.group({
      species: '',
      daily_price: '',
    })
  }

  addTakeCare() {
    this.takeCareArrays.push(this.newTakeCare());
  }

  updateTakeCare(i: number) {
    const updated = this.takeCareArrays.at(i).value;
    const original = this.prices[i];
    console.log(updated);
    if (original == undefined) {
      this.addTakeCareHttp(updated);
      return;
    }
    this.updateTakeCareHttp(updated);
  }

  public updateTakeCareHttp(details) {
    this.http.put(baseurl + '/api/caretaker/updateprice', details, getHttpOptionsWithAuth()).subscribe(x => {
      console.log(x);
      if (!x) {
        alert("Incorrect Params");
      } else {
        this.msg = "Updated Successfully!";
      }
    });
  }
  
  public addTakeCareHttp(details) {
    if (this.is_fulltime) {
      this.http.post(baseurl + '/api/caretaker/ft/addprice', details, getHttpOptionsWithAuth()).subscribe(x => {
        console.log("sending"+x);
        if (!x) {
          alert("Incorrect Params"); 
        } else {
          this.msg = "Updated Successfully!";
          this.getPrices();
        }
      });
    } else {
      this.http.post(baseurl + '/api/caretaker/pt/addprice', details, getHttpOptionsWithAuth()).subscribe(x => {
        console.log(x);
        if (!x) {
          alert("Incorrect Params"); 
        } else {
          this.msg = "Updated Successfully!";
          this.getPrices();
        }
      });
    }
  }

  public removeTakeCareHttp(details) {
    this.http.post(baseurl + '/api/caretaker/removeprice', details, getHttpOptionsWithAuth()).subscribe(x => {
      console.log(x);
    });
  }

  removeTakeCare(i: number) {
    const removed = this.takeCareArrays.at(i).value;
    this.removeTakeCareHttp(removed);
    this.takeCareArrays.removeAt(i);
  }

  onSubmitTakeCareArray() {
    console.log(this.takeCareForm.value);
  }
}
