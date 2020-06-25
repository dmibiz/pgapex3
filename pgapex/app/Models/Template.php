<?php

namespace App\Models;

use PDO;

class Template extends Model {
  public function getLoginTemplates() {
    return $this->getPageTemplatesOfType('LOGIN');
  }

  public function getPageTemplates() {
    return $this->getPageTemplatesOfType('NORMAL');
  }

  private function getPageTemplatesOfType($pageType) {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_template_get_page_templates(:pageType)');
    $statement->bindValue(':pageType', $pageType);
    $statement->execute();
    return $statement->fetchColumn();
  }

  public function getRegionTemplates() {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_template_get_region_templates()');
    $statement->execute();
    return $statement->fetchColumn();
  }

  public function getNavigationTemplates() {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_template_get_navigation_templates()');
    $statement->execute();
    return $statement->fetchColumn();
  }

  public function getReportTemplates() {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_template_get_report_templates()');
    $statement->execute();
    return $statement->fetchColumn();
  }

  public function getReportLinkTemplates() {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_template_get_report_link_templates()');
    $statement->execute();
    return $statement->fetchColumn();
  }

  public function getDetailViewTemplates() {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_template_get_detailview_templates()');
    $statement->execute();
    return $statement->fetchColumn();
  }

  public function getFormTemplates() {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_template_get_form_templates()');
    $statement->execute();
    return $statement->fetchColumn();
  }

  public function getTabularFormTemplates() {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_template_get_tabularform_templates()');
    $statement->execute();
    return $statement->fetchColumn();
  }

  public function getButtonTemplates() {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_template_get_button_templates()');
    $statement->execute();
    return $statement->fetchColumn();
  }

  public function getTextareaTemplates() {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_template_get_textarea_templates()');
    $statement->execute();
    return $statement->fetchColumn();
  }

  public function getDropDownTemplates() {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_template_get_drop_down_templates()');
    $statement->execute();
    return $statement->fetchColumn();
  }

  public function getTabularFormButtonTemplates() {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_template_get_tabularform_button_templates()');
    $statement->execute();
    return $statement->fetchColumn();
  }

  public function getInputTemplates($inputType) {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_template_get_input_templates(:inputType)');
    $statement->bindValue(':inputType', strtoupper($inputType), PDO::PARAM_STR);
    $statement->execute();
    return $statement->fetchColumn();
  }

  public function getComboBoxTemplates() {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_template_get_combo_box_templates()');
    $statement->execute();
    return $statement->fetchColumn();
  }

  public function getCalendarTemplates() {
    $connection = $this->getDb()->getConnection();
    $statement = $connection->prepare('SELECT pgapex.f_template_get_calendar_templates()');
    $statement->execute();
    return $statement->fetchColumn();
  }
}